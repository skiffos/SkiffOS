#!/bin/bash
set -eo pipefail

if [ -z "$BR2_GRAPH_OUT" ]; then
    BR2_GRAPH_OUT=png
    echo "Using ${BR2_GRAPH_OUT} output, set BR2_GRAPH_OUT to override."
else
    echo "Using BR2_GRAPH_OUT=${BR2_GRAPH_OUT} output."
fi

cd ${BUILDROOT_DIR}/
BR2_GRAPH_OUT=${BR2_GRAPH_OUT} make graph-size

echo "Target size graphs are available in the graphs directory of your workspace."
