#!/bin/sh

VAR=$1
VAL=$2

if [ ! -f ./overrides.sh ]; then
    echo "overrides.sh not found"
    exit 1
fi

if [ -n "$VAR" ] && [ -n "$VAL" ]; then
    if [ "$VAL" == "none" ]; then
        VAL=""
    fi
    echo "Setting override ${VAR}=${VAL}..."
    echo "export ${VAR}=\"${VAL}\"" >> ./overrides.sh
fi
