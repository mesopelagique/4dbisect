#!/bin/bash

version=$1
root=$2

myBase=$HOME/Bisect # customize it

path=$root/$version/release/INTL/mac_INTL_64/4D_INTL_x86_64.zip

unzipPath=$(mktemp -d)

if [[ -f "$path" ]]; then
    unzip -q '$path' $unzipPath

    if [[ -f "$unzipPath/4D/4D.app/Contents/MacOS/4D" ]]; then
        $unzipPath/4D/4D.app/Contents/MacOS/4D --headless --dataless -s "$myBase/Project/builder.4DProject" # run onStart of this project, must auto QUIT

        # failed if a file has been created in resources (for install an error handler and create the file if an assert occurs)
        # if 4D return error code, it will be better, just return its code with $? 
        if [[ -f "$myBase/Resources/error" ]]; then
            rm -Rf $unzipPath
            exit 1
        else
            rm -Rf $unzipPath
            exit 0
        fi
    else
        >&2 echo "No 4D command in zip $path"
        exit 125 # skip
    fi
else
    exit 125 # skip
fi