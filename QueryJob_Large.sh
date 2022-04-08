#!/bin/bash
# set the STRING variable
URL="https://attone.my.salesforce.com"
SESSION="00D6g000005jkYJ!AQUAQJUl3s9qlEwzRtuoVUqF98pPrWjX4IMDpsov1zjyEPxjcWvQWBfiHW6R8VgUDNuGQd.3gzOjZljQW5694DZ4keqNZlwm"
VALIDCOMMANDS="create,status,results"

runJob(){
	echo "$1"

	if [[ "$1" == "create" ]]
	then
		echo "ENTER THE FILE NAME AND EXTENSION OF YOUR QUERY FILE:"
		read jobTextFile
		echo "Creating JOB for ${jobTextFile} Configuration"
		curl \
		-H "Authorization: Bearer ${SESSION}" \
		-H "Content-Type: application/json" \
		-d "@${jobTextFile}" \
		"${URL}/services/data/v52.0/jobs/query"

	elif [[ "$1" == "status" ]]
	then
		echo "ENTER THE JOB ID FOR WHICH YOU NEED STATUS OF"
		read jobId
		echo "${URL}/services/data/v52.0/jobs/query/${jobId}"
		JOBSTATUS=$(curl \
		-H "Authorization: Bearer ${SESSION}" \
		-H "Content-Type: application/json" \
		"${URL}/services/data/v52.0/jobs/query/${jobId}")

		echo "JOB STATUS: \n ${JOBSTATUS}"
	elif [[ "$1" == "results" ]]
	then
		if [[ ! -d "Results" ]]
		then
			mkdir "Results"
		fi
		
		echo "ENTER THE JOB ID FOR WHICH YOU NEED RESULTS OF:"
		read jobId
		echo "DO YOU NEED SMALLER BATCHES ?(Yes/No)"
		read smallbatch
		if [[ "$smallbatch" == "Yes" ]] 
		then
			if [[ ! -d "$Results/jobId" ]]
			then
				mkdir "Results/$jobId"
			fi
			counter=1
			echo "ENTER MAXRECORDS TO EXPORT IN EACH FILE"
			read maxRecords
			echo "${URL}/services/data/v52.0/jobs/query/${jobId}"
			curl \
			--include --header GET \
			-H "Authorization: Bearer ${SESSION}" \
			-H "Content-Type: text/csv" \
			"${URL}/services/data/v52.0/jobs/query/${jobId}/results?maxRecords=${maxRecords}" \
			> "Results/${jobId}/${jobId}_QueryResults_${counter}.csv"
			echo "RESULTS SAVED IN Results/${jobId}/${jobId}_QueryResults_${counter}.csv"
			
			locator=""
			while [[ "$locator" != "null" ]]
			do
				for loc in `grep -A 1 "sforce-locator: " "Results/${jobId}/${jobId}_QueryResults_${counter}.csv" | grep -E 'sforce-locator: |"$'`
				do
					locator="${loc}"
				done
				
				counter=$((counter+1))
				if [[ "$locator" != "null"  ]]
				then
					curl \
					--include --header GET \
					-H "Authorization: Bearer ${SESSION}" \
					-H "Content-Type: text/csv" \
					"${URL}/services/data/v52.0/jobs/query/${jobId}/results?locator=${locator}&maxRecords=${maxRecords}" \
					> "Results/${jobId}/${jobId}_QueryResults_${counter}.csv"
					echo "RESULTS SAVED IN Results/${jobId}/${jobId}_QueryResults_${counter}.csv"
				else
					echo "Export is Completed."
				fi
				
			done
		else
			echo "${URL}/services/data/v52.0/jobs/query/${jobId}"
			curl \
			-H "Authorization: Bearer ${SESSION}" \
			-H "Content-Type: text/csv" \
			"${URL}/services/data/v52.0/jobs/query/${jobId}/results?maxRecords=50000000" \
			> "Results/${jobId}_QueryResults.csv"
			echo "RESULTS SAVED IN Results/${jobId}_QueryResults.csv"	
		fi		
	else
		echo "You entered Invalid Command ${1}. Please choose one from these: ${VALIDCOMMANDS}"
	fi
}

nextCommand=""
while [ "$nextCommand" != "exit" ]
do
	echo "ENTER A COMMAND (ACCEPTED VALUES : ${VALIDCOMMANDS})"
	read nextCommand
	runJob "$nextCommand"
done