#!/bin/bash
#######################################
# Check VM instances in every gcloud project
# Written by Daniel Castillo
# 19/11/2021
#######################################
#The below line will do an action for every project in the project list
for project in $(cat projects.txt); do
 #This gcloud command will run for every instance of project in projectlist
 gcloud config set project $project
 os="Ubuntu"
 printf "\n$(gcloud compute instances os-inventory list-instances --os-shortname="$os" --filter="status:(RUNNING)" --format="table[box,margin=2,title='Instances on $project running $os'](NAME,ZONE,MACHINE_TYPE,INTERNAL_IP,STATUS)")\n"
   mapfile -t nameInst < <( gcloud compute instances os-inventory list-instances --os-shortname="$os" --filter="status:(RUNNING)" | tail -n +2 | awk '{print $1}' )
   mapfile -t zoneInst < <( gcloud compute instances os-inventory list-instances --os-shortname="$os" --filter="status:(RUNNING)" | tail -n +2 | awk '{print $2}' )
   for index in ${!nameInst[*]}; do 
     printf "\n$(gcloud compute instances os-inventory describe ${nameInst[$index]} --zone ${zoneInst[$index]} | grep -A 9 Architecture)\n "
   done

   #ouput to csv
done >>output.csv



