#!/usr/bin/env bash

TMP="${TMPDIR}"
if [ "x$TMP" = "x" ]; then
  TMP="/tmp/"
fi
TMP="${TMP}4dbisect.$$"
rm -rf "$TMP" || true
mkdir "$TMP"
if [ $? -ne 0 ]; then
  echo "failed to mkdir $TMP" >&2
  exit 1
fi

cd $TMP

if [[ "$OSTYPE" == "linux-gnu" ]]; then
  archiveName=4dbisect.tar.gz
elif [[ "$OSTYPE" == "darwin"* ]]; then  # Mac OSX
  archiveName=4dbisect.zip
else
  echo "Unknown os type $OSTYPE"
  archiveName=4dbisect.tar.gz
fi

archive=$TMP/$archiveName
curl -sL https://github.com/mesopelagique/4dbisect/releases/latest/download/$archiveName -o $archive

if [[ "$OSTYPE" == "darwin"* ]]; then  # Mac OSX
  unzip -q $archive -d $TMP/
else
  tar -zxf $archive -C $TMP/
fi

binary=$TMP/.build/release/kaluza 

dst="/usr/local/bin"
echo "Install into $dst/4dbisect"
sudo rm -f $dst/4dbisect
sudo cp $binary $dst/

rm -rf "$TMP"
