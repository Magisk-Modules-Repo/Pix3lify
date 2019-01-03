#!/bin/sh
INSTALLER=$(dirname "${BASH_SOURCE[0]}")/../
VERSION=$(cat $INSTALLER/module.prop | grep version= | cut -d "=" -f2)
BRANCH=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)
ZIP=builds/Pix3lify_"$BRANCH".zip

echo "Building $VERSION from $BRANCH of Pix3lify\n"
cd $INSTALLER
mkdir -p builds
zip -r $ZIP ./ -x "*.git*" -x "*.DS_Store" -x "./builds/*"
echo "\nCreated $ZIP"

read -p "Do you want to push to device? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  adb push $ZIP /sdcard/Download/
fi
