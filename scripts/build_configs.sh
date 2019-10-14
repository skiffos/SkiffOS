#!/bin/bash
set -e

OLDPATH=$(pwd)
ACTION_COLOR=$(tput smso)
RESET_COLOR=$(tput sgr0)

function join_by { local IFS="$1"; shift; echo "$*"; }

# Build config like this:
# - configs/base
# - alphabetical: SKIFF_CONFIG_PATH/buildroot/config
# Merge them together, tell buildroot to use it as a defconfig
# Also merges kernel defconfigs
SKIFF_PRE_CONFIG_DIR=$SKIFF_BASE_CONFIGS_DIR/pre
SKIFF_POST_CONFIG_DIR=$SKIFF_BASE_CONFIGS_DIR/post
SKIFF_OVERRIDES_CONFIG_DIR=$SKIFF_OVERRIDES_DIR
SKIFF_WS_OVERRIDES_CONFIG_DIR=$SKIFF_WS_OVERRIDES_DIR

# Determine if we should skip rebuilding the config.
if (
if [ -n "$SKIFF_FORCE_RECONFIG" ]; then
    echo "${ACTION_COLOR}Rebuilding configuration as requested...${RESET_COLOR}"
    exit 1
fi
if [ ! -f $SKIFF_FINAL_CONFIG_DIR/skiff_version ]; then
    echo "${ACTION_COLOR}Old skiff version detected, rebuilding config.$RESET_COLOR"
    exit 1
fi
OLD_SKIFF_VERSION=$(cat $SKIFF_FINAL_CONFIG_DIR/skiff_version)
if [ "$OLD_SKIFF_VERSION" != "$SKIFF_VERSION" ]; then
    echo "${ACTION_COLOR}Configuration was built with ${OLD_SKIFF_VERSION}, we have ${SKIFF_VERSION}, rebuilding config.${RESET_COLOR}"
    exit 1
fi
if [ -f $SKIFF_FINAL_CONFIG_DIR/skiff_config ]; then
    exist_conf=$(cat $SKIFF_FINAL_CONFIG_DIR/skiff_config)
    if [ "$exist_conf" == "$SKIFF_CONFIG" ]; then
        echo "${ACTION_COLOR}Skiff config matches $SKIFF_CONFIG, skipping config rebuild.$RESET_COLOR"
        exit 0
    fi
fi
exit 1
); then
    exit 0
fi

echo "${ACTION_COLOR}Building effective kernel and buildroot configs...$RESET_COLOR"

# Make a temporary work dir
SKIFF_BRCONF_WORK_DIR=$(mktemp -d)
function cleanup {
  rm -rf "$SKIFF_BRCONF_WORK_DIR"
  cd $OLDPATH
}
trap cleanup EXIT

# Setup the configs dir
rm -rf "$SKIFF_FINAL_CONFIG_DIR"
mkdir -p "$SKIFF_FINAL_CONFIG_DIR"

# Make some scary warnings
cp $SKIFF_RESOURCES_DIR/text/temp_confdir_warning $SKIFF_FINAL_CONFIG_DIR/WARNING
cp $SKIFF_RESOURCES_DIR/text/temp_confdir_warning $SKIFF_FINAL_CONFIG_DIR/DO_NOT_EDIT

# Save the SKIFF_CONFIG chain.
echo "$SKIFF_CONFIG" > $SKIFF_FINAL_CONFIG_DIR/skiff_config
if [ -n "$SKIFF_EXTRA_CONFIGS_PATH" ]; then
  echo "$SKIFF_EXTRA_CONFIGS_PATH" > $SKIFF_FINAL_CONFIG_DIR/skiff_extra_configs_path
fi

# Save the version
echo "$SKIFF_VERSION" > $SKIFF_FINAL_CONFIG_DIR/skiff_version

# Touch the initial files
kern_dir=$SKIFF_FINAL_CONFIG_DIR/kernel
kern_conf=$kern_dir/config
mkdir -p $kern_dir
touch $kern_conf

uboot_dir=$SKIFF_FINAL_CONFIG_DIR/uboot
uboot_conf=$uboot_dir/config
mkdir -p $uboot_dir
touch $uboot_conf

users_conf=$SKIFF_FINAL_CONFIG_DIR/users
touch $users_conf

# Make the scripts wrappers
bind_env="$(env | grep 'SKIFF_*' | sed 's/^/export /' | sed 's/=/=\"/' | sed 's/$/\"/')"
bind_path_env="export PATH=$BUILDROOT_DIR/output/host/bin:$BUILDROOT_DIR/output/host/sbin:\$PATH"
bind_env_script=$SKIFF_FINAL_CONFIG_DIR/bind_env.sh
pre_build_script=$SKIFF_FINAL_CONFIG_DIR/pre_build.sh
post_build_script=$SKIFF_FINAL_CONFIG_DIR/post_build.sh
echo "#!/bin/bash" > $bind_env_script
echo "$bind_env" >> $bind_env_script
echo "$bind_path_env" >> $bind_env_script
echo "export BUILDROOT_DIR=${BUILDROOT_DIR}" >> $bind_env_script
printf "#!/bin/bash\nset -eo pipefail\nsource $bind_env_script\ncd ${BUILDROOT_DIR}\n" > $post_build_script
cat $post_build_script > $pre_build_script
chmod +x $post_build_script $pre_build_script

br_dir=$SKIFF_FINAL_CONFIG_DIR/buildroot
br_conf=$br_dir/config
mkdir -p $br_dir
touch $br_conf

# Iterate over skiff config paths.
# Add the post path
cd $SKIFF_BRCONF_WORK_DIR
echo "Config path: "

SKIFF_CONFIG_PATH=("$SKIFF_PRE_CONFIG_DIR" "${SKIFF_CONFIG_PATH[@]}" "$SKIFF_OVERRIDES_CONFIG_DIR" "$SKIFF_WS_OVERRIDES_CONFIG_DIR" "$SKIFF_POST_CONFIG_DIR")
echo ${SKIFF_CONFIG_PATH[@]}
domerge="$SKIFF_SCRIPTS_DIR/merge_config.sh -O $SKIFF_BRCONF_WORK_DIR -m -r"
rootfs_overlays=()
br_exts=()
kern_patches=()
uboot_patches=()
confpaths=(${SKIFF_CONFIG_PATH[@]})
for confp in "${confpaths[@]}"; do
  echo "Merging Skiff config at $confp"
  br_confp=$confp/buildroot
  kern_confp=$confp/kernel
  uboot_confp=$confp/uboot
  kern_patchp=$confp/kernel_patches
  uboot_patchp=$confp/uboot_patches
  rootfsp=$confp/root_overlay
  usersp=$confp/users
  br_extp=$confp/buildroot_ext
  if [ -d "$br_extp" ]; then
    if [ ! -f "$br_extp/external.mk" ] || \
       [ ! -f "$br_extp/external.desc" ] || \
       [ ! -f "$br_extp/Config.in" ]; then \
      echo "Buildroot extension directory $br_extp invalid, see https://buildroot.org/downloads/manual/manual.html#outside-br-custom"
      exit 1
    else
      br_exts+=("$br_extp")
    fi
  fi
  if [ -d "$br_confp" ]; then
    for file in $(ls -v $br_confp); do
      # echo "Merging in config file $file"
      printf "\n# Configuration from ${br_confp}/${file}\n" >> $br_conf
      $domerge $br_conf $br_confp/$file
      sed -i -e "s#SKIFF_CONFIG_ROOT#$confp#g" .config
      mv .config $br_conf
    done
  fi
  if [ -d "$kern_confp" ]; then
    for file in $(ls -v $kern_confp); do
      echo "Merging in config file $file"
      printf "\n# Configuration from ${kern_confp}/${file}\n" >> $kern_conf
      $domerge $kern_conf $kern_confp/$file
      sed -i -e "s#SKIFF_CONFIG_ROOT#$confp#g" .config
      mv .config $kern_conf
    done
  fi
  if [ -d "$uboot_confp" ]; then
      for file in $(ls -v $uboot_confp); do
          echo "Merging in u-boot config file $file"
          printf "\n# Configuration from ${uboot_confp}/${file}\n" >> $uboot_conf
          $domerge $uboot_conf $uboot_confp/$file
          sed -i -e "s#SKIFF_CONFIG_ROOT#$confp#g" .config
          mv .config $uboot_conf
      done
  fi
  if [ -d "$rootfsp" ]; then
    echo "Adding root overlay directory..."
    rootfs_overlays+=("$rootfsp")
  fi
  if [ -d "$kern_patchp" ]; then
    echo "Adding kernel patch directory..."
    kern_patches+=("$kern_patchp")
  fi
  if [ -d "$uboot_patchp" ]; then
    echo "Adding uboot patch directory..."
    uboot_patches+=("$uboot_patchp")
  fi
  if [ -d "$usersp" ]; then
    for file in $(ls -v $usersp); do
      cat $usersp/$file >> $users_conf
    done
  fi
  pre_hook_pat="$confp/hooks/pre.sh"
  if [ -f "$pre_hook_pat" ]; then
    echo "Adding pre-image hook..."
    echo "SKIFF_CURRENT_CONF_DIR=\"$confp\" $pre_hook_pat" >> $pre_build_script
  fi
  post_hook_pat="$confp/hooks/post.sh"
  if [ -f "$post_hook_pat" ]; then
    echo "SKIFF_CURRENT_CONF_DIR=\"$confp\" $post_hook_pat" >> $post_build_script
  fi
done

# Rewrite arrays
kern_patches=${kern_patches[@]}
rootfs_overlays=${rootfs_overlays[@]}
uboot_patches=${uboot_patches[@]}

# Touch up the buildroot
sed -i "s@REPLACEME_KERNEL_FRAGMENTS@$kern_conf@g" $br_conf
sed -i "s@REPLACEME_KERNEL_PATCHES@$kern_patches@g" $br_conf
sed -i "s@REPLACEME_UBOOT_FRAGMENTS@$uboot_conf@g" $br_conf
sed -i "s@REPLACEME_UBOOT_PATCHES@$uboot_patches@g" $br_conf
sed -i "s@REPLACEME_ROOTFS_OVERLAY@$rootfs_overlays@g" $br_conf
sed -i "s@REPLACEME_FINAL_CONFIG_DIR@$SKIFF_FINAL_CONFIG_DIR@g" $br_conf
sed -i "s@REPLACEME_SKIFF_VERSION_COMMIT@$SKIFF_VERSION_COMMIT@g" $br_conf
sed -i "s@REPLACEME_SKIFF_VERSION@$SKIFF_VERSION@g" $br_conf
br_exts=$(join_by : "${br_exts[@]}")

mkdir -p $SKIFF_FINAL_CONFIG_DIR/final
mkdir -p $SKIFF_FINAL_CONFIG_DIR/defconfig
# Build the buildroot config
rm $BUILDROOT_DIR/.config 2>/dev/null || true
# ln -fs $br_conf $BUILDROOT_DIR/.config
(cd $BUILDROOT_DIR && make defconfig BR2_DEFCONFIG=$br_conf BR2_EXTERNAL="${br_exts}")
# Now copy the config
mv $BUILDROOT_DIR/.config $SKIFF_FINAL_CONFIG_DIR/final/buildroot
ln -fs $SKIFF_FINAL_CONFIG_DIR/final/buildroot $BUILDROOT_DIR/.config
