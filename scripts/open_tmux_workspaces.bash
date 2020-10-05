#!/bin/bash

if [ ! -d ./workspaces/ ]; then
    echo "Run from skiff root."
    exit 1
fi

tmux new-session -d -s skiff -n root "cd $(pwd); bash -i"
for wspath in ./workspaces/*; do
    wsbase=$(basename $wspath)
    if [[ $wsbase == .config_* ]]; then
        continue
    fi
    tmux new-window -t 'skiff' -n $wsbase "  cd $(pwd); unset SKIFF_CONFIG; export SKIFF_WORKSPACE=$wsbase; bash -i"
done
tmux select-window -t 'skiff:0'
tmux -2 attach-session -t skiff
