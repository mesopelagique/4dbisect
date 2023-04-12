#!/bin/bash

version=$1
root=$2

myBase="$(pwd)" # customize it

## get project file name
baseName=$(find "$myBase/Project" -name "*.4DProject" 2>/dev/null | head -1)
baseName=$(basename $baseName)
baseName=$(echo ${baseName%.*})

if [ -z "$var" ]
then
    >&2 echo "No 4DProject file found in $myBase/Project"
    exit 1 # TOTO add an other code to stop all process?
fi

path=$root/$version/release/INTL/mac_INTL_64/4D_INTL_x86_64.zip

unzipPath=$(mktemp -d)
cachePath=/Applications/4D/Cache
mkdir -p "$cachePath"

if [[ -f "$path" ]]; then
    if [[ -f "$cachePath/4D-$version.app/Contents/MacOS/4D" ]]; then
        binPath=$cachePath/4D-$version.app/Contents/MacOS/4D
    else
        unzip -q "$path" -d $unzipPath
        binPath="$unzipPath/4D/4D.app/Contents/MacOS/4D"
        cp -R "$unzipPath/4D/4D.app" "$cachePath/4D-$version.app" &
    fi

    if [[ -f "$binPath" ]]; then
        $binPath -s "$myBase/Project/$baseName.4DProject" # run onStart of this project, must auto QUIT

        # failed if a file has been created in resources (for install an error handler and create the file if an assert occurs)
        # if 4D return error code, it will be better, just return its code with $? 
        if [[ -f "$myBase/Resources/error" ]]; then
            rm -Rf "$myBase/Resources/error"
            rm -Rf $unzipPath
            exit 1
        else
            rm -Rf $unzipPath
            exit 0
        fi
    else
        rm -Rf $unzipPath
        >&2 echo "No 4D command in zip $path"
        exit 125 # skip
    fi
else
    exit 125 # skip
fi
