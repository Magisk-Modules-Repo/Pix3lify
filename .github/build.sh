#!/bin/sh
INSTALLER=$(dirname "${BASH_SOURCE[0]}")/../
VERSION=$(cat "$INSTALLER/module.prop" | grep version= | cut -d "=" -f2)
BRANCH=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)
ZIP=builds/Pix3lify_"$BRANCH".zip

echo "Building $VERSION from $BRANCH of Pix3lify\n"
cd $INSTALLER || exit
mkdir -p builds || echo "Failed to create builds folder"
zip -r $ZIP ./ -x "*.git*" -x "*.DS_Store" -x "./builds/*" && echo "\nCreated $ZIP" || echo "Build failed"

read -p "Do you want to push to device? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  ADB_LOCATION=/sdcard/Download/
  echo "Pushing $ZIP to $ADB_LOCATION"
  adb push $ZIP $ADB_LOCATION || echo "Push failed"
fi
