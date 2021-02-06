#!/bin/bash

version=$1
root=$2

path=$root/$version/release/INTL/mac_INTL_64/4D_INTL_x86_64.zip

if [[ -f "$path" ]]; then
    if [ "$version" -gt "241902" ]; then
        exit 1
    else
        exit 0
    fi
else
    exit 125 # skip
fi

