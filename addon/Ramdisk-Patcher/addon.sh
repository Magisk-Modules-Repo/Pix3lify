#!/sbin/sh
# ADDOND_VERSION=2

. /tmp/backuptool.functions

case "$1" in
  backup)
    # Stub
  ;;
  restore)
    # Stub
  ;;
  pre-backup)
    # Stub
  ;;
  post-backup)
    # Stub
  ;;
  pre-restore)
    # Stub
  ;;
  post-restore)
    TMPDIR=/dev/unitytmp; OUTFD=$(ps | grep -v 'grep' | grep -oE 'update(.*)' | cut -d" " -f3)
    [ "$(ls -A $(dirname $C)/addon.d/*-unityrd 2>/dev/null)" -a -d $(dirname $C)/addon.d/unitytools ] || { rm -rf $(dirname $C)/addon.d/unitytools; rm -f $0; exit 0; }
    mkdir -p $TMPDIR
    for i in $(dirname $C)/addon.d/*-unityrd; do cp -f $i $TMPDIR; done
    [ "$(ls -A $(dirname $C)/addon.d/*-unityrdfiles 2>/dev/null)" ] && for i in $(dirname $C)/addon.d/*-unityrdfiles; do cp -rf $i $TMPDIR; done
    cp -R $(dirname $C)/addon.d/unitytools $TMPDIR
    sed -i "s|OUTFD=|OUTFD=$OUTFD|" $TMPDIR/unitytools/functions
    chmod -R 0755 $TMPDIR/unitytools
    # Run in background, hack for addon.d-v1
    if [ -d /postinstall ]; then
      . $TMPDIR/unitytools/functions
    else
      (sleep 7; . $TMPDIR/unitytools/functions) &
    fi
  ;;
esac

