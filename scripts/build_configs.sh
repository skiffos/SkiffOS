#!/usr/bin/env bash
# SkiffOS build configuration generator
# Merges configuration fragments and sets up build environment
set -e

OLDPATH=$(pwd)
ACTION_COLOR=$(tput smso)
RESET_COLOR=$(tput sgr0)

# Join array elements with a delimiter
function join_by() {
	local IFS="$1"
	shift
	echo "$*"
}

# Set up configuration directories
SKIFF_PRE_CONFIG_DIR="${SKIFF_BASE_CONFIGS_DIR}/pre"
SKIFF_POST_CONFIG_DIR="${SKIFF_BASE_CONFIGS_DIR}/post"
SKIFF_OVERRIDES_CONFIG_DIR="${SKIFF_OVERRIDES_DIR}"
SKIFF_WS_OVERRIDES_CONFIG_DIR="${SKIFF_WS_OVERRIDES_DIR}"

# Check previous CFLAGS if set
PREVIOUS_TARGET_CFLAGS=""
if [[ -f "${SKIFF_FINAL_CONFIG_DIR}/cflags" ]]; then
	PREVIOUS_TARGET_CFLAGS=$(cat "${SKIFF_FINAL_CONFIG_DIR}/cflags")
fi

# Determine if we should skip rebuilding the config
if (
	if [[ -n $SKIFF_FORCE_RECONFIG ]]; then
		echo "${ACTION_COLOR}Rebuilding configuration as requested...${RESET_COLOR}"
		exit 1
	fi

	if [[ ! -f "${SKIFF_FINAL_CONFIG_DIR}/skiff_version" ]]; then
		echo "${ACTION_COLOR}Old skiff version detected, rebuilding config.${RESET_COLOR}"
		exit 1
	fi

	OLD_SKIFF_VERSION=$(cat "${SKIFF_FINAL_CONFIG_DIR}/skiff_version")
	if [[ $OLD_SKIFF_VERSION != "$SKIFF_VERSION" ]]; then
		echo "${ACTION_COLOR}Configuration was built with ${OLD_SKIFF_VERSION}, we have ${SKIFF_VERSION}, rebuilding config.${RESET_COLOR}"
		exit 1
	fi

	if [[ -f "${SKIFF_FINAL_CONFIG_DIR}/skiff_config" ]]; then
		exist_conf=$(cat "${SKIFF_FINAL_CONFIG_DIR}/skiff_config")
		if [[ $exist_conf == "$SKIFF_CONFIG" ]]; then
			echo "${ACTION_COLOR}Skiff config matches $SKIFF_CONFIG, skipping config rebuild.${RESET_COLOR}"
			exit 0
		fi
	fi

	exit 1
); then
	exit 0
fi

echo "${ACTION_COLOR}Building effective kernel and buildroot configs...${RESET_COLOR}"

# Make a temporary work directory
SKIFF_BRCONF_WORK_DIR=$(mktemp -d)
function cleanup {
	rm -rf "${SKIFF_BRCONF_WORK_DIR}"
	cd "${OLDPATH}"
}
trap cleanup EXIT

# Setup the configs directory
rm -rf "${SKIFF_FINAL_CONFIG_DIR}"
mkdir -p "${SKIFF_FINAL_CONFIG_DIR}"

# Add warning notices
cp "${SKIFF_RESOURCES_DIR}/text/temp_confdir_warning" "${SKIFF_FINAL_CONFIG_DIR}/WARNING"
cp "${SKIFF_RESOURCES_DIR}/text/temp_confdir_warning" "${SKIFF_FINAL_CONFIG_DIR}/DO_NOT_EDIT"

# Save the SKIFF_CONFIG chain
echo "$SKIFF_CONFIG" >"${SKIFF_FINAL_CONFIG_DIR}/skiff_config"
if [[ -n $SKIFF_EXTRA_CONFIGS_PATH ]]; then
	echo "$SKIFF_EXTRA_CONFIGS_PATH" >"${SKIFF_FINAL_CONFIG_DIR}/skiff_extra_configs_path"
fi

# Save the version
echo "$SKIFF_VERSION" >"${SKIFF_FINAL_CONFIG_DIR}/skiff_version"

# Initialize configuration directories and files
# Kernel config
kern_dir="${SKIFF_FINAL_CONFIG_DIR}/kernel"
kern_conf="${kern_dir}/config"
mkdir -p "${kern_dir}"
touch "${kern_conf}"

# U-Boot config
uboot_dir="${SKIFF_FINAL_CONFIG_DIR}/uboot"
uboot_conf="${uboot_dir}/config"
mkdir -p "${uboot_dir}"
touch "${uboot_conf}"

# Users config
users_conf="${SKIFF_FINAL_CONFIG_DIR}/users"
touch "${users_conf}"

# Create environment binding scripts
bind_env="$(env | grep 'SKIFF_*' | sed 's/^/export /' | sed 's/=/=\"/' | sed 's/$/\"/')"
# Note: adding buildroot sbin causes issues on many systems
bind_path_env="export PATH=${BUILDROOT_DIR}/output/host/bin:\$PATH"
bind_env_script="${SKIFF_FINAL_CONFIG_DIR}/bind_env.sh"
pre_build_script="${SKIFF_FINAL_CONFIG_DIR}/pre_build.sh"
post_build_script="${SKIFF_FINAL_CONFIG_DIR}/post_build.sh"

# Write environment binding script
cat >"${bind_env_script}" <<EOF
#!/bin/bash
${bind_env}
${bind_path_env}
export BUILDROOT_DIR=${BUILDROOT_DIR}
EOF

# Write pre/post build scripts
cat >"${pre_build_script}" <<EOF
#!/bin/bash
set -eo pipefail
source ${bind_env_script}
cd ${BUILDROOT_DIR}
EOF

cp "${pre_build_script}" "${post_build_script}"
chmod +x "${post_build_script}" "${pre_build_script}"

# Initialize buildroot config
br_dir="${SKIFF_FINAL_CONFIG_DIR}/buildroot"
br_conf="${br_dir}/config"
mkdir -p "${br_dir}"
touch "${br_conf}"

# Initialize busybox config
busybox_dir="${SKIFF_FINAL_CONFIG_DIR}/busybox"
busybox_conf="${busybox_dir}/config"
mkdir -p "${busybox_dir}"
touch "${busybox_conf}"

# Merge configuration from all paths
cd "${SKIFF_BRCONF_WORK_DIR}"
echo "Config path: "

# Construct full configuration path including pre/post and overrides
SKIFF_CONFIG_PATH=("${SKIFF_PRE_CONFIG_DIR}" "${SKIFF_CONFIG_PATH[@]}" "${SKIFF_OVERRIDES_CONFIG_DIR}" "${SKIFF_WS_OVERRIDES_CONFIG_DIR}" "${SKIFF_POST_CONFIG_DIR}")
echo "${SKIFF_CONFIG_PATH[@]}"

# Set up merge command
domerge="${SKIFF_SCRIPTS_DIR}/merge_config.sh -O ${SKIFF_BRCONF_WORK_DIR} -m -r"

# Initialize collection arrays
rootfs_overlays=()
br_exts=()
br_patches=()
kern_patches=()
uboot_patches=()
addl_target_cflags=()

# Process each configuration path
confpaths=("${SKIFF_CONFIG_PATH[@]}")
for confp in "${confpaths[@]}"; do
	echo "Merging Skiff config at $confp"

	# Define paths for various config components
	br_confp="${confp}/buildroot"
	busybox_confp="${confp}/busybox"
	cflags_confp="${confp}/cflags"
	kern_confp="${confp}/kernel"
	uboot_confp="${confp}/uboot"
	kern_patchp="${confp}/kernel_patches"
	uboot_patchp="${confp}/uboot_patches"
	rootfsp="${confp}/root_overlay"
	usersp="${confp}/users"
	br_extp="${confp}/buildroot_ext"
	br_patchp="${confp}/buildroot_patches"

	# Process buildroot extension
	if [[ -d ${br_extp} ]]; then
		if [[ ! -f "${br_extp}/external.mk" ]] ||
			[[ ! -f "${br_extp}/external.desc" ]] ||
			[[ ! -f "${br_extp}/Config.in" ]]; then
			echo "Buildroot extension directory ${br_extp} invalid, see https://buildroot.org/downloads/manual/manual.html#outside-br-custom"
			exit 1
		else
			br_exts+=("${br_extp}")
		fi
	fi

	# Merge buildroot config fragments
	if [[ -d ${br_confp} ]]; then
		for file in $(ls -v "${br_confp}" | sort); do
			echo "Merging in Buildroot config file $file"
			printf "\n# Configuration from ${br_confp}/${file}\n" >>"${br_conf}"
			${domerge} "${br_conf}" "${br_confp}/${file}"
			sed -i -e "s#SKIFF_CONFIG_ROOT#${confp}#g" .config
			mv .config "${br_conf}"
		done
	fi

	# Merge busybox config fragments
	if [[ -d ${busybox_confp} ]]; then
		for file in $(ls -v "${busybox_confp}" | sort); do
			echo "Merging in Busybox config file $file"
			printf "\n# Configuration from ${busybox_confp}/${file}\n" >>"${busybox_conf}"
			${domerge} "${busybox_conf}" "${busybox_confp}/${file}"
			sed -i -e "s#SKIFF_CONFIG_ROOT#${confp}#g" .config
			mv .config "${busybox_conf}"
		done
	fi

	# Process CFLAGS
	if [[ -d ${cflags_confp} ]]; then
		for file in $(ls -v "${cflags_confp}" | sort); do
			echo "Merging in Cflags config file $file"
			ncflags=$(cat "${cflags_confp}/${file}" | sed -e '/^[ \t]*#/d' | tr '\n' ' ')
			if [[ -z $ncflags ]]; then
				echo "Note: file had no effect."
				continue
			fi
			printf "\n# Configuration from ${br_confp}/${file}\n" >>"${br_conf}"
			printf "# CFLAGS: \"${ncflags}\"\n" >>"${br_conf}"
			addl_target_cflags+=("${ncflags}")
			echo "CFLAGS appended for target: \"${ncflags}\""
		done
	fi

	# Merge kernel config fragments
	if [[ -d ${kern_confp} ]]; then
		for file in $(ls -v "${kern_confp}" | sort); do
			echo "Merging in Kernel config file $file"
			printf "\n# Configuration from ${kern_confp}/${file}\n" >>"${kern_conf}"
			${domerge} "${kern_conf}" "${kern_confp}/${file}"
			sed -i -e "s#SKIFF_CONFIG_ROOT#${confp}#g" .config
			mv .config "${kern_conf}"
		done
	fi

	# Merge U-Boot config fragments
	if [[ -d ${uboot_confp} ]]; then
		for file in $(ls -v "${uboot_confp}" | sort); do
			echo "Merging in u-boot config file $file"
			printf "\n# Configuration from ${uboot_confp}/${file}\n" >>"${uboot_conf}"
			${domerge} "${uboot_conf}" "${uboot_confp}/${file}"
			sed -i -e "s#SKIFF_CONFIG_ROOT#${confp}#g" .config
			mv .config "${uboot_conf}"
		done
	fi

	# Add root overlay directory
	if [[ -d ${rootfsp} ]]; then
		echo "Adding root overlay directory..."
		rootfs_overlays+=("${rootfsp}")
	fi

	# Add kernel patch directory
	if [[ -d ${kern_patchp} ]]; then
		echo "Adding kernel patch directory..."
		kern_patches+=("${kern_patchp}")
	fi

	# Add U-Boot patch directory
	if [[ -d ${uboot_patchp} ]]; then
		echo "Adding uboot patch directory..."
		uboot_patches+=("${uboot_patchp}")
	fi

	# Add Buildroot patch directory
	if [[ -d ${br_patchp} ]]; then
		echo "Adding Buildroot patch directory..."
		br_patches+=("${br_patchp}")
	fi

	# Add user configurations
	if [[ -d ${usersp} ]]; then
		echo "Adding users configs..."
		for file in $(ls -v "${usersp}" | sort); do
			cat "${usersp}/${file}" >>"${users_conf}"
		done
	fi

	# Add pre-build hook
	pre_hook_pat="${confp}/hooks/pre.sh"
	if [[ -f ${pre_hook_pat} ]]; then
		echo "Adding pre-image hook..."
		echo "echo \"\$(tput smso)Executing hook: ${pre_hook_pat}\$(tput sgr0)\"" >>"${pre_build_script}"
		echo "SKIFF_CURRENT_CONF_DIR=\"${confp}\" ${pre_hook_pat}" >>"${pre_build_script}"
	fi

	# Add post-build hook
	post_hook_pat="${confp}/hooks/post.sh"
	if [[ -f ${post_hook_pat} ]]; then
		echo "Adding post-image hook..."
		echo "echo \"\$(tput smso)Executing hook: ${post_hook_pat}\$(tput sgr0)\"" >>"${post_build_script}"
		echo "SKIFF_CURRENT_CONF_DIR=\"${confp}\" ${post_hook_pat}" >>"${post_build_script}"
	fi
done

# Convert arrays to space-separated strings for substitution
br_patches="${br_patches[*]}"
kern_patches="${kern_patches[*]}"
rootfs_overlays="${rootfs_overlays[*]}"
uboot_patches="${uboot_patches[*]}"
addl_target_cflags="${addl_target_cflags[*]}"

# Substitute placeholders in buildroot config
sed -i "s@REPLACEME_BR_PATCHES@${br_patches}@g" "${br_conf}"
sed -i "s@REPLACEME_BUSYBOX_FRAGMENTS@${busybox_conf}@g" "${br_conf}"
sed -i "s@REPLACEME_KERNEL_FRAGMENTS@${kern_conf}@g" "${br_conf}"
sed -i "s@REPLACEME_KERNEL_PATCHES@${kern_patches}@g" "${br_conf}"
sed -i "s@REPLACEME_UBOOT_FRAGMENTS@${uboot_conf}@g" "${br_conf}"
sed -i "s@REPLACEME_UBOOT_PATCHES@${uboot_patches}@g" "${br_conf}"
sed -i "s@REPLACEME_ROOTFS_OVERLAY@${rootfs_overlays}@g" "${br_conf}"
sed -i "s@REPLACEME_FINAL_CONFIG_DIR@${SKIFF_FINAL_CONFIG_DIR}@g" "${br_conf}"
sed -i "s@REPLACEME_SKIFF_VERSION_COMMIT@${SKIFF_VERSION_COMMIT}@g" "${br_conf}"
sed -i "s@REPLACEME_SKIFF_VERSION@${SKIFF_VERSION}@g" "${br_conf}"

# Add ccache directory
echo "BR2_CCACHE_DIR=\"${BR2_CCACHE_DIR}\"" >>"${br_conf}"

# Handle target optimization flags
if [[ -n ${addl_target_cflags} ]]; then
	# Warn if overriding BR2_TARGET_OPTIMIZATION
	if grep -q 'BR2_TARGET_OPTIMIZATION' "${br_conf}"; then
		printf "\nNOTE: your BR2_TARGET_OPTIMIZATION flags will be overridden.\n"
		printf "Please move these into the \"cflags\" configuration dir in files:\n"
		grep -nh 'BR2_TARGET_OPTIMIZATION' "${br_conf}"
		printf "\n\n"
	fi

	echo "CFLAGS: ${addl_target_cflags}"
	cflags_override_conf="${SKIFF_FINAL_CONFIG_DIR}/buildroot/cflags"
	echo "BR2_TARGET_OPTIMIZATION=\"${addl_target_cflags}\"" >"${cflags_override_conf}"
	echo "Merging in cflags to Buildroot config..."
	${domerge} "${br_conf}" "${cflags_override_conf}"
	rm "${cflags_override_conf}" || true
	mv .config "${br_conf}"
fi

# Save current target CFLAGS
echo "${addl_target_cflags}" >"${SKIFF_FINAL_CONFIG_DIR}/cflags"

# Force GCC reconfiguration if CFLAGS changed
if [[ ${PREVIOUS_TARGET_CFLAGS} != "${addl_target_cflags}" ]]; then
	echo "Forcing GCC re-configuration after cflags changed:"
	echo "Old cflags: ${PREVIOUS_TARGET_CFLAGS}"
	echo "New cflags: ${addl_target_cflags}"
	rm "${BUILDROOT_DIR}"/build/*gcc-*-*/.stamp_{built,configured,host_installed,installed} 2>/dev/null || true
fi
unset PREVIOUS_TARGET_CFLAGS

# Prepare final config directories
mkdir -p "${SKIFF_FINAL_CONFIG_DIR}/final"
mkdir -p "${SKIFF_FINAL_CONFIG_DIR}/defconfig"

# Build buildroot config
rm "${BUILDROOT_DIR}/.config" 2>/dev/null || true
# Join BR_EXTERNAL paths with colons
br_exts=$(join_by : "${br_exts[@]}")
(cd "${BUILDROOT_DIR}" && make defconfig BR2_DEFCONFIG="${br_conf}" BR2_EXTERNAL="${br_exts}")

# Copy final config
mv "${BUILDROOT_DIR}/.config" "${SKIFF_FINAL_CONFIG_DIR}/final/buildroot"
ln -fs "${SKIFF_FINAL_CONFIG_DIR}/final/buildroot" "${BUILDROOT_DIR}/.config"
