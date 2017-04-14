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

if [ -z "$SKIFF_FORCE_RECONFIG" ]; then
  if [ -f $SKIFF_FINAL_CONFIG_DIR/skiff_config ]; then
    exist_conf=$(cat $SKIFF_FINAL_CONFIG_DIR/skiff_config)
    if [ "$exist_conf" == "$SKIFF_CONFIG" ]; then
      echo "${ACTION_COLOR}Skiff config matches $SKIFF_CONFIG, skipping config rebuild.$RESET_COLOR"
      exit 0
    fi
  fi
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

# Touch the initial files
kern_dir=$SKIFF_FINAL_CONFIG_DIR/kernel
kern_conf=$kern_dir/config
mkdir -p $kern_dir
touch $kern_conf

users_conf=$SKIFF_FINAL_CONFIG_DIR/users
touch $users_conf

# Make the scripts wrappers
bind_env="$(env | grep 'SKIFF_*' | sed 's/^/export /' | sed 's/=/=\"/' | sed 's/$/\"/')"
post_build_script=$SKIFF_FINAL_CONFIG_DIR/post_build.sh
echo "#!/bin/bash" > $post_build_script
echo "$bind_env" >> $post_build_script
chmod +x $post_build_script
pre_build_script=$SKIFF_FINAL_CONFIG_DIR/pre_build.sh
echo "#!/bin/bash" > $pre_build_script
echo "$bind_env" >> $pre_build_script
chmod +x $pre_build_script

br_dir=$SKIFF_FINAL_CONFIG_DIR/buildroot
br_conf=$br_dir/config
mkdir -p $br_dir
touch $br_conf

# Iterate over skiff config paths.
# Add the post path
cd $SKIFF_BRCONF_WORK_DIR
echo "Config path: "
SKIFF_CONFIG_PATH=("$SKIFF_PRE_CONFIG_DIR" "${SKIFF_CONFIG_PATH[@]}" "$SKIFF_POST_CONFIG_DIR")
echo ${SKIFF_CONFIG_PATH[@]}
domerge="$SKIFF_SCRIPTS_DIR/merge_config.sh -O $SKIFF_BRCONF_WORK_DIR -m -r"
rootfs_overlays=()
br_exts=()
kern_patches=()
confpaths=(${SKIFF_CONFIG_PATH[@]})
for confp in "${confpaths[@]}"; do
  echo "Merging Skiff config at $confp"
  br_confp=$confp/buildroot
  kern_confp=$confp/kernel
  kern_patchp=$confp/kernel_patches
  rootfsp=$confp/root_overlay
  usersp=$confp/users
  br_extp=$confp/buildroot_ext
  if [ -d "$br_extp" ]; then
    if [ ! -f "$br_extp/external.mk" ] || \
       [ ! -f "$br_extp/external.desc"] || \
       [ ! -f "$br_extp/Config.in"]; then \
      echo "Buildroot extension directory $br_extp invalid, see https://buildroot.org/downloads/manual/manual.html#outside-br-custom"
    else
      br_exts+=("$br_extp")
    fi
  fi
  if [ -d "$br_confp" ]; then
    for file in $(ls -v $br_confp); do
      # echo "Merging in config file $file"
      $domerge $br_conf $br_confp/$file
      sed -i -e "s#SKIFF_CONFIG_ROOT#$confp#g" .config
      mv .config $br_conf
    done
  fi
  if [ -d "$kern_confp" ]; then
    for file in $(ls -v $kern_confp); do
      echo "Merging in config file $file"
      $domerge $kern_conf $kern_confp/$file
      sed -i -e "s#SKIFF_CONFIG_ROOT#$confp#g" .config
      mv .config $kern_conf
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

# Touch up the buildroot
sed -i "s@REPLACEME_KERNEL_FRAGMENTS@$kern_conf@g" $br_conf
kern_patchesa="${kern_patches[@]}"
sed -i "s@REPLACEME_KERNEL_PATCHES@$kern_patchesa@g" $br_conf
overlays="${rootfs_overlays[@]}"
sed -i "s@REPLACEME_ROOTFS_OVERLAY@$overlays@g" $br_conf
sed -i "s@REPLACEME_FINAL_CONFIG_DIR@$SKIFF_FINAL_CONFIG_DIR@g" $br_conf
br_exts=$(join_by : "${br_exts[@]}")

mkdir -p $SKIFF_FINAL_CONFIG_DIR/final
mkdir -p $SKIFF_FINAL_CONFIG_DIR/defconfig
# Build the buildroot config
rm $BUILDROOT_DIR/.config 2>/dev/null || true
# ln -fs $br_conf $BUILDROOT_DIR/.config
(cd $BUILDROOT_DIR && make defconfig BR2_DEFCONFIG=$br_conf)
# Now copy the config
mv $BUILDROOT_DIR/.config $SKIFF_FINAL_CONFIG_DIR/final/buildroot
ln -fs $SKIFF_FINAL_CONFIG_DIR/final/buildroot $BUILDROOT_DIR/.config

# echo "${ACTION_COLOR}Re-generating defconfig...$RESET_COLOR"
# regen defconfig
if [ -n "$br_exts" ]; then
  (
    cd $BUILDROOT_DIR
    make savedefconfig \
      BR2_DEFCONFIG=$SKIFF_FINAL_CONFIG_DIR/defconfig/buildroot \
      BR2_EXTERNAL="${br_exts}"
  )
fi
