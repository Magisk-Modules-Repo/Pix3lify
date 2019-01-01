#!/bin/sh
INSTALLER=$(dirname "${BASH_SOURCE[0]}")/../
VERSION=$(cat $INSTALLER/module.prop | grep version= | cut -d "=" -f2)
ZIP=builds/Pix3lify_"$VERSION".zip

echo "Building $VERSION of Pix3lify\n"
cd $INSTALLER
mkdir -p builds
zip -r $ZIP ./ -x "*.git*" -x "*.DS_Store" -x "./builds/*"
echo "\nCreated $ZIP"
