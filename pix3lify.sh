# Terminal Magisk Mod Template
# by veez21 @ xda-developer

get_file_value() {
  cat $1 | grep $2 | sed "s|.*$2||" | sed 's|\"||g'
}

MAGISK_VERSION=$(echo $(get_file_value /data/adb/magisk/util_functions.sh "MAGISK_VER=") | sed 's|-.*||')
MAGISK_VERSIONCODE=$(echo $(get_file_value /data/adb/magisk/util_functions.sh "MAGISK_VER_CODE=") | sed 's|-.*||')

if [ $MAGISK_VERSIONCODE -ge "18000" ]; then
  MOUNTPATH=/sbin/.magisk/img
else
  MOUNTPATH=/sbin/.core/img
fi

MODPATH=$MOUNTPATH/Pix3lify

# Variables
OLDPATH=$PATH
CACHELOC=<CACHELOC>
BINPATH=<BINPATH>
SDCARD=/storage/emulated/0
TMPLOG=Pix3lify_logs.log
TMPLOGLOC=$CACHELOC/Pix3lify_logs
XZLOG=$SDCARD/Pix3lify_logs.tar.xz
DPF=$(find /data/data/com.google.android.dialer*/shared_prefs/ -name "dialer_phenotype_flags.xml")

quit() {
  PATH=$OLDPATH
  exit $?
}

MODPROP=<MODPROP>
$MAGISK && [ ! -f $MODPROP ]
[ -f $MODPROP ] || { echo "Module not detected!"; quit 1; }

# Detect root
_name=$(basename $0)
ls /data >/dev/null 2>&1 || { echo "$MODID needs to run as root!"; echo "type 'su' then '$_name'"; quit 1; }

if [ -f $VEN/build.prop ]; then BUILDS="/system/build.prop $VEN/build.prop"; else BUILDS="/system/build.prop"; fi

#=========================== Set Log Files
mount -o remount,rw $CACHELOC 2>/dev/null
mount -o rw,remount $CACHELOC 2>/dev/null
# > Logs should go in this file
LOG=$CACHELOC/Pix3lify.log
oldLOG=$CACHELOC/Pix3lify-old.log
# > Verbose output goes here
VERLOG=$CACHELOC/Pix3lify-verbose.log
oldVERLOG=$CACHELOC/Pix3lify-verbose-old.log

# Start Logging verbosely
mv -f $VERLOG $oldVERLOG 2>/dev/null
set -x 2>$VERLOG

# Loggers
LOGGERS="
$CACHELOC/magisk.log
$CACHELOC/magisk.log.bak
$CACHELOC/Pix3lify-install.log
$SDCARD/Pix3lify-debug.log
$CACHELOC/pix3lify
/data/adb/magisk_debug.log
$DPF
$CACHELOC/Pix3lify.log
$CACHELOC/Pix3lify-old.log
$CACHELOC/Pix3lify-verbose-old.log
"

log_handler() {
	if [ $(id -u) == 0 ] ; then
		echo "" >> $LOG 2>&1
		echo -e "$(date +"%m-%d-%Y %H:%M:%S") - $1" >> $LOG 2>&1
	fi
}

log_print() {
	echo "$1"
	log_handler "$1"
}

log_script_chk() {
	log_handler "$1"
	echo -e "$(date +"%m-%d-%Y %H:%M:%S") - $1" >> $LOG 2>&1
}

get_file_value() {
	cat $1 | grep $2 | sed "s|.*$2||" | sed 's|\"||g'
}

#ZACKPTG5 BUSYBOX
#=========================== Set Busybox up
if [ "$(busybox 2>/dev/null)" ]; then
  BBox=true
elif $MAGISK && [ -d /sbin/.magisk/busybox ]; then
  PATH=/sbin/.magisk/busybox:$PATH
	_bb=/sbin/.magisk/busybox/busybox
  BBox=true
else
  BBox=false
  echo "! Busybox not detected"
	echo "Please install one (@osm0sis' busybox recommended)"
  for applet in cat chmod cp grep md5sum mv printf sed sort tar tee tr wget; do
    [ "$($applet)" ] || quit 1
  done
  echo "All required applets present, continuing"
fi
if $BBox; then
  alias cat="busybox cat"
  alias chmod="busybox chmod"
  alias cp="busybox cp"
  alias grep="busybox grep"
  alias md5sum="busybox md5sum"
  alias mv="busybox mv"
  alias printf="busybox printf"
  alias sed="busybox sed"
  alias sort="busybox sort"
  alias tar="busybox tar"
  alias tee="busybox tee"
  alias tr="busybox tr"
  alias wget="busybox wget"
fi

if [ -z "$(echo $PATH | grep /sbin:)" ]; then
	alias resetprop="/data/adb/magisk/magisk resetprop"
fi

# Log print
log_handler "Functions loaded."
if $BBox; then
  BBV=$(busybox | grep "BusyBox v" | sed 's|.*BusyBox ||' | sed 's| (.*||')
  log_handler "Using busybox: ${PATH} (${BBV})."
else
  log_handler "Using installed applets (not busybox)"
fi

grep_prop() {
  REGEX="s/^$1=//p"
  shift
  FILES=$@
  [ -z "$FILES" ] && FILES='/system/build.prop'
  sed -n "$REGEX" $FILES 2>/dev/null | head -n 1
}

api_level_arch_detect() {
  API=`grep_prop ro.build.version.sdk`
  ABI=`grep_prop ro.product.cpu.abi | cut -c-3`
  ABI2=`grep_prop ro.product.cpu.abi2 | cut -c-3`
  ABILONG=`grep_prop ro.product.cpu.abi`
  ARCH=arm
  ARCH32=arm
  IS64BIT=false
  if [ "$ABI" = "x86" ]; then ARCH=x86; ARCH32=x86; fi;
  if [ "$ABI2" = "x86" ]; then ARCH=x86; ARCH32=x86; fi;
  if [ "$ABILONG" = "arm64-v8a" ]; then ARCH=arm64; ARCH32=arm; IS64BIT=true; fi;
  if [ "$ABILONG" = "x86_64" ]; then ARCH=x64; ARCH32=x86; IS64BIT=true; fi;
}

magisk_version() {
  if grep MAGISK_VER /data/adb/magisk/util_functions.sh; then
		log_print "$MAGISK_VERSION $MAGISK_VERSIONCODE" >> $LOG 2>&1
	else
		log_print "Magisk not installed" >> $LOG 2>&1
	fi
}

# Device Info
# BRAND MODEL DEVICE API ABI ABI2 ABILONG ARCH
BRAND=$(getprop ro.product.brand)
MODEL=$(getprop ro.product.model)
DEVICE=$(getprop ro.product.device)
ROM=$(getprop ro.build.display.id)
api_level_arch_detect
# Version Number
VER=$(grep_prop version $MODPROP)
# Version Code
REL=$(grep_prop versionCode $MODPROP)
# Author
AUTHOR=$(grep_prop author $MODPROP)
# Mod Name/Title
MODTITLE=$(grep_prop name $MODPROP)
#Grab Magisk Version
MAGISK_VERSION=$(echo $(get_file_value /data/adb/magisk/util_functions.sh "MAGISK_VER=") | sed 's|-.*||')
MAGISK_VERSIONCODE=$(echo $(get_file_value /data/adb/magisk/util_functions.sh "MAGISK_VER_CODE=") | sed 's|-.*||')

# Colors
G='\e[01;32m'		# GREEN TEXT
R='\e[01;31m'		# RED TEXT
Y='\e[01;33m'		# YELLOW TEXT
B='\e[01;34m'		# BLUE TEXT
V='\e[01;35m'		# VIOLET TEXT
Bl='\e[01;30m'		# BLACK TEXT
C='\e[01;36m'		# CYAN TEXT
W='\e[01;37m'		# WHITE TEXT
BGBL='\e[1;30;47m'	# Background W Text Bl
N='\e[0m'			# How to use (example): echo "${G}example${N}"
loadBar=' '			# Load UI
# Remove color codes if -nc or in ADB Shell
[ -n "$1" -a "$1" == "-nc" ] && shift && NC=true
[ "$NC" -o -n "$LOGNAME" ] && {
	G=''; R=''; Y=''; B=''; V=''; Bl=''; C=''; W=''; N=''; BGBL=''; loadBar='=';
}

# Divider (based on $MODTITLE, $VER, and $REL characters)
character_no=$(echo $MODTITLE $VER $REL | tr " " '_' | wc -c)
div="${Bl}$(printf '%*s' "${character_no}" '' | tr " " "=")${N}"

# Title Div
title_div() {
	no=$(echo $@ | wc -c)
	extdiv=$((no-character_no))
	echo "${W}$@${N} ${Bl}$(printf '%*s' "$extdiv" '' | tr " " "=")${N}"
}

# https://github.com/fearside/ProgressBar
ProgressBar() {
# Process data
	_progress=$(((${1}*100/${2}*100)/100))
	_done=$(((${_progress}*4)/10))
	_left=$((40-$_done))
# Build progressbar string lengths
	_done=$(printf "%${_done}s")
	_left=$(printf "%${_left}s")

# 1.2 Build progressbar strings and print the ProgressBar line
# 1.2.1 Output example:
# 1.2.1.1 Progress : [########################################] 100%
printf "\rProgress : ${BGBL}|${N}${_done// /${BGBL}$loadBar${N}}${_left// / }${BGBL}|${N} ${_progress}%%"
}

# test_connection
test_connection() {
	echo -n "Testing internet connection "
	ping -q -c 1 -W 1 google.com >/dev/null 2>/dev/null && echo "- OK" || { echo "Error"; false; }
}

# Log files will be uploaded to logs.pix3lify.com
upload_logs() {
  test_connection
  [ $? -ne 0 ] && exit
  logup=none;
  echo "Uploading logs"
  [ -s $XZLOG ] && logup=$(curl -T $XZLOG http://logs.pix3lify.com/submit)
  echo "$MODEL ($DEVICE) API $API\n$ROM\n$ID\n
  Log:   $logup"
  exit
}


# Heading
mod_head() {
	clear
	echo "$div"
	echo "${W}$MODTITLE $VER${N}(${Bl}$REL${N})"
	echo "by ${W}$AUTHOR${N}"
	echo "$div"
  echo "${W}$BRAND,$MODEL,$DEVICE,$ROM${N}"
  echo "$div"
  echo "${W}$PATH${N}"
	echo "${W}$BBV${N}"
	echo "${W}$_bb${N}"
	echo "$div"
if $MAGISK; then
	magisk_version
	echo "$div"
fi
}

#=========================== Main
# > You can start your MOD here.
# > You can add functions, variables & etc.
# > Rather than editing the default vars above.

#Log Functions
# Saves the previous log (if available) and creates a new one
log_start() {
if [ -f "$LOG" ]; then
	mv -f $LOG $oldLOG
fi
touch $LOG
echo " " >> $LOG 2>&1
echo "    *********************************************" >> $LOG 2>&1
echo "    *               Pix3lify                    *" >> $LOG 2>&1
echo "    *********************************************" >> $LOG 2>&1
echo "    *                 $VER                      *" >> $LOG 2>&1
echo "    *********************************************" >> $LOG 2>&1
echo "    *       Joey Huab, Aidan Holland, Pika      *" >> $LOG 2>&1
echo "    *     John Fawkes, Laster K. (lazerl0rd)    *" >> $LOG 2>&1
echo "    *********************************************" >> $LOG 2>&1
echo " " >> $LOG 2>&1
log_script_chk "Log start."
}

# PRINT MOD NAME
log_start

collect_logs() {
	log_handler "Collecting logs and information."
	# Create temporary directory
	mkdir -pv $TMPLOGLOC >> $LOG 2>&1

	# Saving Magisk and module log files and device original build.prop
	for ITEM in $LOGGERS; do
		if [ -f "$ITEM" ]; then
			case "$ITEM" in
				*build.prop*)	BPNAME="build_$(echo $ITEM | sed 's|\/build.prop||' | sed 's|.*\/||g').prop"
				;;
				*)	BPNAME=""
				;;
			esac
			cp -af $ITEM ${TMPLOGLOC}/${BPNAME} >> $LOG 2>&1
		else
			case "$ITEM" in
				*/cache)
					if [ "$CACHELOC" == "/cache" ]; then
						CACHELOCTMP=/cache
					else
						CACHELOCTMP=/data/cache
					fi
					ITEMTPM=$(echo $ITEM | sed 's|$CACHELOC|$CACHELOCTMP|')
					if [ -f "$ITEMTPM" ]; then
						cp -af $ITEMTPM $TMPLOGLOC >> $LOG 2>&1
					else
						log_handler "$ITEM not available."
					fi
        ;;
				*)	log_handler "$ITEM not available."
				;;
			esac
    fi
	done

# Saving the current prop values
if $MAGISK; then
  log_handler "RESETPROPS"
  echo "==========================================" >> $LOG 2>&1
	resetprop >> $LOG 2>&1
else
  log_handler "GETPROPS"
  echo "==========================================" >> $LOG 2>&1
	getprop >> $LOG 2>&1
fi
if $MAGISK; then
  log_print " Collecting Modules Installed "
  echo "==========================================" >> $LOG 2>&1
  if [ $MAGISK_VERSIONCODE -ge "18000" ]; then
    ls /sbin/.magisk/img >> $LOG 2>&1
  else
    ls /sbin/.core/img >> $LOG 2>&1
  fi
  log_print " Collecting Logs for Installed Files "
  echo "==========================================" >> $LOG 2>&1
  log_handler "$(du -ah $MODPATH)" >> $LOG 2>&1
  log_print " Collecting Logs for Patches "
  echo "==========================================" >> $LOG 2>&1
  grep "$MODID" -B 1 $DPF >> $LOG 2>&1
fi

# Package the files
cd $CACHELOC
tar -zcvf Pix3lify_logs.tar.xz Pix3lify_logs >> $LOG 2>&1

# Copy package to internal storage
mv -f $CACHELOC/Pix3lify_logs.tar.xz $SDCARD >> $LOG 2>&1

if  [ -e $SDCARD/Pix3lify_logs.tar.xz ]; then
  log_print "Pix3lify_logs.tar.xz Created Successfully."
else
  log_print "Archive File Not Created. Error in Script. Please contact the Pix3lify Team"
fi

# Remove temporary directory
rm -rf $TMPLOGLOC >> $LOG 2>&1

log_handler "Logs and information collected."
}

# Load functions
log_start "Running Log script." >> $LOG 2>&1

menu() {
  choice=""

while [ "$choice" != "q" ];
  do
   log_start
  echo "$div"
  echo ""
  echo "__________._______  ___________ .____    .___________________.___."
  echo "\______   \   \   \/  /\_____  \|    |   |   \_   _____/\__  |   |"
  echo " |     ___/   |\     /   _(__  <|    |   |   ||    __)   /   |   |"
  echo " |    |   |   |/     \  /       \    |___|   ||     \    \____   |"
  echo " |____|   |___/___/\  \/______  /_______ \___|\___  /    / ______|"
  echo "                    \_/       \/        \/        \/     \/       "
  echo ""
  echo "$div"
  mod_head
  echo ""
  echo "${G}Welcome to the logging section of PIX3LIFY!${N}"
	echo "${G}If you are expirencing any bugs or issues then${N}"
  echo "${G}please send us logs. After choosing yes below the script${N}"
  echo "${G}will automatically gather the needed files and create a tar.xz${N}"
  echo "${G}in your internal storage then send the tar.xz to our server${N}"
  echo "${G}It will then delete the tar.xz from your device${N}"
	echo "${G}WE DO NOT COLLECT ANY PERSONAL INFORMATION!${N}"
  echo "$div"
  echo ""
  echo -e "${B}Please make a Selection${N}"
  echo ""

  echo -e "${W}L)${N} ${B}Logging${N}"
  echo ""
  echo -e "${W}Q)${N} ${B}Quit${N}"
  echo "$div"
  echo ""
  echo -n "${R}[CHOOSE] :  ${N}"

read -r choice
  case $choice in
  l|L) log_print " Collecting logs and creating archive "
  magisk_version
  collect_logs
  upload_logs
  rm -f $SDCARD/Pix3lify_logs.tar.xz
  break
  ;;
  q|Q) echo "${R}quiting!${N}"
  clear
  quit
  ;;
  *) echo "${Y}item not available! Try Again${N}"
  clear
  ;;
  esac
done
echo -n "${R}quit? < y | n > : ${N}"
read -r mchoice
[ "$mchoice" = "n" ] && menu || clear && quit
}

menu

quit $?
