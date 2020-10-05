export SKIFF_PACKAGE_ENV_PREFIX=SKIFF_CONFIG_PATH_
export SKIFF_PACKAGE_NAME_ENV_PREFIX=SKIFF_CONFIG_NAME_
export SKIFF_FILTER_ENVS="grep ^$SKIFF_PACKAGE_ENV_PREFIX[[:alnum:]]*_.*="

# Config paths
export SKIFF_CONFIG_METADATA_SUBDIR=metadata
export SKIFF_CONFIG_METADATA_DESCRIPTION=description
export SKIFF_CONFIG_METADATA_NOLIST=unlisted
export SKIFF_CONFIG_METADATA_UNIQUEGROUP=uniquegroup

# Fixups
force_arr() {
    if [ -n "${!1}" ] ; then
        if ! [[ "$(declare -p $1 2>/dev/null)" =~ "declare -a" ]]; then
            eval "export $1=( \${$1} )"
        fi
    fi
}
force_arr SKIFF_CONFIG_PATH
force_arr SKIFF_CONFIGS
#if [ -n "$SKIFF_CONFIG_PATH" ]; then
#    if ! [[ "$(declare -p SKIFF_CONFIG_PATH 2>/dev/null)" =~ "declare -a" ]]; then
#        SKIFF_CONFIG_PATH=( ${SKIFF_CONFIG_PATH} )
#    fi
#fi
