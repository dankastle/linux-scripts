#!/bin/bash
#######################################
# Check VM instances in every gcloud project
# Written by Daniel Castillo
# 19/11/2021
#######################################
#The below line will do an action for every project in the project list
for project in $(cat projects_new); do
  #This gcloud command will run for every instance of project in projectlist
  gcloud config set project $project
  printf "$project\n $(gcloud compute instances list --filter="status:(RUNNING)")\n"

#ouput to csv
done >>output.csv
