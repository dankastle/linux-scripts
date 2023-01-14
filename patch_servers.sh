#!/bin/bash
##############################################################
# patch_servers.sh
# by Daniel Castillo
# Nov, 2022
# REVISION HISTORY
# Version 1.0
# DESCRIPTION
# This script updates each of the server.txt list
# It´s designed to run from a jumpserver
##############################################################

# --- Options processing -------------------------------------------

#Variables
CURRENT_KERNEL=$(uname -r | awk -F '-' '{print $1 "-" $2}')i
LATEST_KERNEL=$(ls /boot/vmlinuz-4* | sort -V | awk -F '-' '{print $2 "-" $3}' | tail -n 1)
OLDEST_KERNEL=$(ls /boot/vmlinuz-4* | sort -V | awk -F '-' '{print $2 "-" $3}' | head -n 1)
BOOT_DISK_SPACE=$(df -h /boot | tail -1 | awk '{ print substr( $5, 1, length($5)-1 ) }')
ROOT_DISK_SPACE=$(df -h / | tail -1 | awk '{ print substr( $5, 1, length($5)-1 ) }')

#Functions
symlink_latest_kernel() {
  cd /boot
  sudo mv initrd.img initrd.img.bak
  sudo mv vmlinuz vmlinuz.bak
  sudo ln -s initrd.img-$LATEST_KERNEL-generic initrd.img
  sudo ln -s vmlinuz-$LATEST_KERNEL-generic vmlinuz
}

purge_oldest_kernel() {
  sudo apt-get purge -y $(dpkg -l | grep $OLDEST_KERNEL | awk '{print $2}')
}

run_packages_update() {
  sudo apt-get --allow-releaseinfo-change update
  sudo apt-mark hold salt-minion salt-common
  sudo apt -y autoremove
  sudo apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
  sudo systemctl stop ossec
  sudo salt-call state.highstate && sudo salt-call state.highstate
}

#Code
if [ $ROOT_DISK_SPACE -lt 90 ]; then
  run_packages_update
    if [ $CURRENT_KERNEL != $LATEST_KERNEL ]; then
      symlink_latest_kernel
    fi
else
  result="There is not sufficient disk space on "/" to run update"
  exit 1
fi
