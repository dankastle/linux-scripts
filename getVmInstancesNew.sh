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
  nameInst=$(gcloud compute instances list --filter="status:(RUNNING)" | head -2 | tail -1 | awk '{print $1}')
  zoneInst=$(gcloud compute instances list --filter="status:(RUNNING)" | head -2 | tail -1 | awk '{print $2}')
  printf "\n$(gcloud compute instances list --filter="status:(RUNNING)" --format="table[box,margin=4,title='Instances on $project'](NAME,ZONE,MACHINE_TYPE,INTERNAL_IP,STATUS)") \
  \n$(gcloud compute instances os-inventory describe $nameInst --zone $zoneInst | grep -A 9 Architecture)\n"

#ouput to csv
done >>output.csv
