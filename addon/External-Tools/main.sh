# External Tools

[ -f $INSTALLER/addon/External-Tools/tools.tar.xz ] && tar -xf $INSTALLER/addon/External-Tools/tools.tar.xz -C $INSTALLER/addon/External-Tools 2>/dev/null
chmod -R 0755 $INSTALLER/addon/External-Tools
cp -R $INSTALLER/addon/External-Tools/tools $INSTALLER/common/unityfiles 2>/dev/null
PATH=$INSTALLER/common/unityfiles/tools/other:$PATH
