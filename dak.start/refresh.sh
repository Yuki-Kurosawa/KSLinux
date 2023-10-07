#! /bin/bash


SHOW_PROGRESS(){
 if [ -f /usr/bin/dialog ];then
  echo $[$OK*100/$ALL]|dialog --backtitle "$BTITLE" --title "$TITLE" --gauge "$1" 8 50 $[$OK*100/$ALL] 2>/dev/null
  sleep 1
 else
  echo "$1 $2"
 fi
}

SHOW_MIXPROGRESS(){
 if [ -f /usr/bin/dialog ];then
  dialog --backtitle "$BTITLE" --title "$TITLE" --mixedgauge "" 0 0 "$[$OK*100/$ALL]" "$@" 2>/dev/null
  sleep 1
 else
  echo "$1"
 fi
}

USER_CMD="sudo -E -u dak -s -H"
DAK="$USER_CMD /srv/dak/bin/dak"
APT="$USER_CMD apt download"
APTS="$USER_CMD apt source"
DI="$DAK import -s jammy main "


cd /home/dak

BTITLE="Add Packages to DAK"
TITLE="Finalizing Repository"
OK=0
ALL=2

SHOW_MIXPROGRESS "Generate Package Source $1 ... " "PROCESSING" "Generate Repo Release $1 ... " "WAITING"
$DAK generate-packages-sources2 1>/dev/null 2>&1
OK=$[$OK+1]
SHOW_MIXPROGRESS "Generate Package Source $1 ... " "DONE" "Generate Repo Release $1 ... " "PROCESSING"
$DAK generate-release 1>/dev/null 2>&1
OK=$[$OK+1]
SHOW_MIXPROGRESS "Generate Package Source $1 ... " "DONE" "Generate Repo Release $1 ... " "DONE"

clear

cp -r /test.tmp /test/pkgs
arch-chroot /test /bin/bash -c "apt --allow-unauthenticated update && apt --allow-unauthenticated install $2"