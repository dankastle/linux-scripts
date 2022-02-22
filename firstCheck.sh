#!/bin/bash
##############################################################
# firstCheck.sh
# by Daniel Castillo
# February 16, 2018
#
# usage firstCheck.sh <hostname>
# REVISION HISTORY
# Version 1.0
# DESCRIPTION
# This script grows swap based in amount of RAM 
# Version 1.1
# This script also add new disk to LVM
# Version 1.2
# Also Set Hostname
# Version 1.3
# Also Disable IPV6
# Version 1.4
# Also set NTP
##############################################################
diskBlackList="/dev/sda"
fileHostname=/root/hostname
releaseVer=$(lsb_release -r | awk '{ print $2}')

#Change Hostname
echo "$1" > $fileHostname
hostname -F $fileHostname
rm -rf $fileHostname
hostName=$(hostname -s)

#Disable IPv6
case $releaseVer in
"7.4")
  printf "net.ipv6.conf.all.disable_ipv6 = 1" > /etc/sysctl.d/ipv6.conf 2>&1 > /dev/null
  sysctl -p /etc/sysctl.d/ipv6.conf 2>&1 > /dev/null
  dracut -f 
  ;;
  
"6.9")
  printf "net.ipv6.conf.all.disable_ipv6 = 1\nnet.ipv6.conf.default.disable_ipv6 = 1\n" >> /etc/sysctl.conf
  cp -p /etc/hosts /etc/hosts.disableipv6
  sed -i 's/^[[:space:]]*::/#::/' /etc/hosts
  chkconfig ip6tables off
;;

"5.11")
  cp -p /etc/hosts /etc/hosts.disableipv6
  sed -i 's/^[[:space:]]*::/#::/' /etc/hosts
  chkconfig ip6tables off
;;

esac

##Add records in hosts file 
cat <<EOT >> /etc/hosts
172.31.239.53      denother
172.22.1.65        medusa
172.22.17.178      opscenter
EOT

#Set NTP service
ntpService() {
case $releaseVer in  
"7.4")
  printf "server 172.31.239.53 iburst\nallow 127.0.0.1\n" > /etc/chrony.conf && systemctl restart chronyd 2>&1 > /dev/null
;;
"6.9")
  printf "server 172.31.239.53 iburst\nrestrict default kod nomodify notrap nopeer noquery\nrestrict 127.0.0.1\n" > /etc/ntp.conf && /etc/init.d/ntpd restart 2>&1 > /dev/null
;;
"5.11")
  printf "server 172.31.239.53 iburst\nrestrict default kod nomodify notrap nopeer noquery\nrestrict 127.0.0.1\n" > /etc/ntp.conf && /etc/init.d/ntpd restart 2>&1 > /dev/null
;;
esac
}

#From here detect new disk and set Swap
roundMemTotal() {
    totalMem=$(free -m | head -2 | tail -1 | awk '{print $2}')
	#if [[ $totalMem =~ [0-9]+M ]]
	if [[ $totalMem -lt 1000 ]]
	    then
	        totalMem="1"
	    else
		totalMem=$(printf '%.f\n' $(echo "$totalMem / 1000" | bc -l))
	fi	
		roundMem=$totalMem

}

roundSwapTotal() {
    totalSwap=$(free -m | tail -1 | awk '{print $2}')
	if [[ $totalSwap -lt 1000 ]]    
	    then
                totalSwap="1"
            else
                totalSwap=$(printf '%.f\n' $(echo "$totalSwap / 1000" | bc -l))
        fi
		roundSwap=$totalSwap
}

checkSwapRule() {
    fitSwap=$(($roundMem * 2))
	if [ $fitSwap -eq $roundSwap ]
	    then
		printf "%s\n" "The SWAP memory is already 2 times the RAM, no further actions are required"
	#	#bash	       
		exit
	elif [ $fitSwap -lt $roundSwap ]
	    then
		printf "%s\n" "The SWAP memory is already 2 times or more the RAM, no further actions are required"
         #       #bash
                exit	
	else 	
#		printf "%s\n" "SWAP memory is less than recommended, it should be $fitSwap"G""
#		sleep 2	
		scanNewDisks
#		printf "%s\n" "Fixing..."
#		sleep 2
	fi
#	scanNewDisks
#		printf "%s\n" "A new device has been detected in: ${newDev}"
#		sleep 2	
#		printf "%s\n" "Creating a new partition on ${newDev}"
#		sleep 2
#	doPartition
#	fi
}

scanNewDisks() {
#Rescan the SCSI Bus to Add a SCSI Device Without rebooting the VM
for i in $(ls /sys/class/scsi_host/); 
	do echo "- - -" > /sys/class/scsi_host/$i/scan 2>&1 > /dev/null;
		done
# Looks for unpartitioned disks
     declare -a RET
        ls -1 /dev/sd*|egrep -v "${diskBlackList}"|egrep -v "[0-9]$" 2>&1 > /dev/null
	if [[ $? -ne 0 ]]; 
	    then
	        printf "%s\n" "There is no new Disks to add"		
#	        printf "%s\n" "Exiting..."		
		    exit 1
	fi
        newDevs=($(ls -1 /dev/sd*|egrep -v "${diskBlackList}"|egrep -v "[0-9]$"))
                for newDev in "${newDevs[@]}";
                    do
# Check each device if there is a "1" partition.  If not,
# "assume" it is not partitioned.
	if [ ! -b ${newDev}1 ];
	    then
	        RET+="${newDev} " 2>&1 > /dev/null;
	fi
#		printf "%s\n" "A new device has been detected in: ${newDev}"
#               sleep 2#              printf "%s\n" "Creating a new partition on ${newDev}"
#               printf "%s\n" "Creating a new partition on ${newDev}"
   #            sleep 2		    
	done
}

doPartition() {
# This function creates one (1) primary partition on the
# disk, using all available space
		for newDev in "${newDevs[@]}";
                    do
			echo ';' | sfdisk ${newDev} 2>&1 > /dev/null;
				done
# Use the bash-specific $PIPESTATUS to ensure we get the correct exit code
# from fdisk and not from echo
	if [ ${PIPESTATUS[1]} -ne 0 ];
	    then
	        echo "An error occurred partitioning ${newDev}" >&2
#		echo "I cannot continue" >&2
		exit
	    else
		doLVM
#		printf "%s\n" "New partition was created on ${newDev}1"
fi
}

doLVM() {
    volumeGroup=$(pvs | head -2 | tail -1 | awk '{print $2}')
	for newDev in "${newDevs[@]}";
            do
                pvcreate ${newDev}1 > /dev/null 2>&1;
#       	printf "%s\n" "Creating new Physical Volume on ${newDev}1" 
                    done	
	
#sleep 2        
	for newDev in "${newDevs[@]}";
            do
                vgextend $volumeGroup ${newDev}1 > /dev/null 2>&1;
 #               printf "%s\n" "Extending Volume $volumeGroup adding ${newDev}1"
                    done

	if [ $? -ne "0" ];
            then
                printf "%s\n" "An error occurred extending VolumeGroup %s, adding PV %s " $volumeGroup ${newDev}1 >&2
                exit
            else
                enableSwap
		#printf "%s\n" "OK"	 
		#sleep 2
	fi
}


enableSwap() {
    currentSwapPath=$(lvdisplay | grep -w lv_swap | head -n 1 | awk '{print $3}')
#	printf "Deactivating current swap %s\n" "$currentSwapPath"        
	swapoff -a > /dev/null 2>&1
#	sleep 2        
#	printf "%s\n" "Activating new SWAP"
#	printf "lvextend %s -L %s""G\n" "$currentSwapPath" "$fitSwap"        
	lvextend $currentSwapPath -L $fitSwap"G" > /dev/null 2>&1
#	sleep 2		
#	printf "mkswap %s\n" "$currentSwapPath"        
	mkswap -f $currentSwapPath > /dev/null 2>&1
#	sleep 2
#	printf "%s\n" "swapon -va"        
        swapon -va > /dev/null 2>&1
	if [ $? -ne 0 ];
            then
                printf "%s\n" "An error occurred activating new swap on: " "$currentSwapPath" >&2
 #                   echo "I cannot continue" >&2
                exit
            else
                printf "%s\n" "OK"
#                   printf "%s\n" "Swap was succesfully extended and activated"
#		    printf "%s\n" "New Hostname is $hostName"
			#bash                    
        fi
}

#setHostName
ntpService
roundMemTotal
roundSwapTotal
checkSwapRule
scanNewDisks
doPartition
doLVM
enableSwap
