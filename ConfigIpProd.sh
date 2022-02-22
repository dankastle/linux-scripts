#!/bin/bash
##############################################################
# prodNetwork.sh
# by Daniel Castillo
# April 24, 2018
# usage $0 <macPro> <ip/mask> [gw] [dns1] [dns2]
# REVISION HISTORY
# Version 1.4
# DESCRIPTION
# This script set the production ip address and default route
##############################################################
if [ $# -lt 2 ]; then
  printf "%s\n" "usage $0 <macProd> <ip/mask> [gw] [dns1][dns2]"  >&2
  exit 1
fi

#Variables
releaseVer=$(lsb_release -r | awk '{ print $2}')
macPro=$1
ipPro=$(printf $2 | cut -d "/" -f 1)
netMask=$(printf $2 | cut -d "/" -f 2)
gateWay=$3
dns1=$4
dns2=$5
ifPro=$(ip add sh | grep -B 1 $macPro | head -1 | cut -d ":" -f 2 | sed  's/ //g')

#Functions
setNewGw() {
    sed -i -e "s/GATEWAY=*//g" /etc/sysconfig/network-scripts/ifcfg-*
    printf "NAME=$ifPro\n"
    "DEVICE=$ifPro\n"
    "ONBOOT=yes\n"
    "BOOTPROTO=static\n"
    "IPADDR=$ipPro\n"
    "PREFIX=$netMask\n"
    "GATEWAY=$gateWay\n" > /etc/sysconfig/network-scripts/ifcfg-$ifPro
        }

setIp() {
    printf "NAME=$ifPro\n"
    "DEVICE=$ifPro\n"
    "ONBOOT=yes\n"
    "BOOTPROTO=static\n"
    "IPADDR=$ipPro\n"
    "PREFIX=$netMask\n" > /etc/sysconfig/network-scripts/ifcfg-$ifPro
}

setDns() {
if [[ "$dns1" != "-" ]]; then
  printf "DNS1=$dns1\n" >> /etc/sysconfig/network-scripts/ifcfg-$ifPro
fi		

if [[ "$dns2" != "-" ]]; then
  printf "DNS2=$dns2\n" >> /etc/sysconfig/network-scripts/ifcfg-$ifPro
fi
}

#Code
if [[ "$gateWay" != "-" ]] && [[ "$gateWay" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  setNewGw
  setDns	
  ifdown $ifPro > /dev/null 2>&1
  ifup $ifPro > /dev/null 2>&1

    if [ $? -eq 0 ]; then
      result="ok"
    else
      result="There was a problem setting IPADDR and GATEWAY"
      exit 1
    fi
else
  setIp
  setDns	
  ifdown $ifPro > /dev/null 2>&1
  ifup $ifPro > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      result="ok"
    else
      result="There was a problem setting IPADDR"
      exit 1
    fi
fi
printf "%s" "$result"
