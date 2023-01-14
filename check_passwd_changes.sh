#!/bin/bash
###########################################
# check_passwd_changes.sh
# by Daniel Castillo
# Jul, 2020
# REVISION HISTORY
# Version 1.0
# DESCRIPTION
# Check and log changes in /etc/passwd file
# run as root
###########################################


#Variables
get_md5hash=$(cut -d : -f 1,6 /etc/passwd | md5sum)
cur_md5hash=$(cat /var/log/current_users 2>/dev/null)
cur_md5hash_file=/var/log/current_users
log_changes=/var/log/user_changes

#Code
if [ -s "$cur_md5hash_file" ]; then
  if [[ $get_md5hash != $cur_md5hash ]]; then
    printf "$(date +%D) $(date +%T) changes occurred\n" >> $log_changes;
    printf "$get_md5hash\n" > $cur_md5hash_file
  fi
else
  printf "$get_md5hash\n" > $cur_md5hash_file
fi
