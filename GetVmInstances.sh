#The below line will do an action for every project in the project list
for project in $(gcloud projects list --format='(project_id)' | egrep -v 'PROJECT_ID');
    do
		#This gcloud command will run for every instance of project in projectlist
		gcloud config set project $project
		printf "$project\n $(gcloud compute instances list)\n\n"

			#ouput to csv
			done >>output.csv