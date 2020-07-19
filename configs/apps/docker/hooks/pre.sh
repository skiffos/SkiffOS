#!/bin/bash

echo "[apps/docker] Merging Docker daemon.json fragments..."
SRC_DJSON=$SKIFF_CURRENT_CONF_DIR/resources/docker/daemon.json
TARGET_DJSON=${SKIFF_WORKSPACE_DIR}/target/etc/docker/daemon.json
TARGET_DJSON_DIR=$(dirname ${TARGET_DJSON})

if [ ! -d ${TARGET_DJSON_DIR} ]; then
    mkdir -p ${TARGET_DJSON_DIR}
fi

# if base config exists, merge it together.
if [ -f ${TARGET_DJSON} ]; then
    # merge with jq, buildroot provides it with host-jq
    jq -s '.[0] * .[1]' ${SRC_DJSON} ${TARGET_DJSON} >\
        ${TARGET_DJSON}.tmp
    mv ${TARGET_DJSON}.tmp ${TARGET_DJSON}
else
    cat ${SRC_DJSON} > ${TARGET_DJSON}
fi

# merge all fragments and delete fragments dir
SRC_FRAGMENTS_DIR=${SKIFF_WORKSPACE_DIR}/target/etc/docker/daemon.json.merge
mkdir -p ${SRC_FRAGMENTS_DIR}
echo "{}" > ${SRC_FRAGMENTS_DIR}/00-skiff-merged-fragments-to-daemon.json
for f in ${SRC_FRAGMENTS_DIR}/*.json ; do
    echo "[apps/docker] Merging docker.json fragment $(basename ${f})..."
    jq -s '.[0] * .[1]' ${TARGET_DJSON} ${f} >\
       ${TARGET_DJSON}.tmp
    mv ${TARGET_DJSON}.tmp ${TARGET_DJSON}
done
rm -rf ${SRC_FRAGMENTS_DIR}

