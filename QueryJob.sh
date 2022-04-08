#!/bin/bash
# set the STRING variable
URL="https://attone--unisearch.my.salesforce.com"
SESSION="00D55000000ASDb!AQ4AQITSXKeTtPejA6h_k4YYiektYQ0uxD24uWmUHL8B7lwJ7BRqfgXhMcrlUebo6zZKfk45XsbuafeVLSQC2oXJmh0d05Eh"
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
		echo "${URL}/services/data/v52.0/jobs/query/${jobId}"
		curl \
		-H "Authorization: Bearer ${SESSION}" \
		-H "Content-Type: text/csv" \
		"${URL}/services/data/v52.0/jobs/query/${jobId}/results?maxRecords=50000000" \
		> "Results/${jobId}_QueryResults.csv"
		echo "RESULTS SAVED IN Results/${jobId}_QueryResults.csv"
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