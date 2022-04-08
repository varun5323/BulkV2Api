#!/bin/bash
# set the STRING variable
URL="https://attone.my.salesforce.com"
SESSION="00D6g000005jkYJ!AQUAQJUl3s9qlEwzRtuoVUqF98pPrWjX4IMDpsov1zjyEPxjcWvQWBfiHW6R8VgUDNuGQd.3gzOjZljQW5694DZ4keqNZlwm"
VERSION="2.0"
INGESTURL="${URL}/services/data/v48.0/jobs/ingest"
VALIDCOMMANDS="create,status,batches,closejob,success,failure,unprocessed,results"
CURRENTJOBID=""
SKIPJOBIDCOMMAND="FALSE"

runJob(){
	#Create Start
	if [[ "$1" == "create" ]] #Create
	then
		echo "Creating ${3} ${2} Job using Bulk API ${VERSION}"
		curl \
			-H "Authorization:Bearer ${SESSION}" \
			-H "Content-Type: application/json" \
			-d '{
				  "object": "'$3'",
				  "contentType":"CSV",
				  "operation":"'$2'",
  				  "lineEnding" : "CRLF"
				}' \
			"${INGESTURL}"
	elif [[ "$1" == "status" ]] #Status
	then
		echo "ENTER THE JOB ID FOR WHICH YOU NEED STATUS OF:"
		read jobId
		JOBSTATUS=$(curl \
		-X GET \
		-H "Authorization:Bearer ${SESSION}" \
		-H "Content-Type: application/json" \
		"${INGESTURL}/${jobId}") 

		echo "JOB STATUS OF ${jobId} : ${JOBSTATUS}"
	elif [[ "$1" == "batches" ]] #Batches
	then
		echo "ENTER THE JOB ID WHERE YOU WANT TO ADD BATCHES:"
		read jobId
		echo "ENTER THE FILE AND EXTENSION NAME OF THE FILE THAT YOU WANT TO PERFORM UPLOAD:"
		read uploadFile
		curl \
			-X PUT \
			-H "Authorization:Bearer ${SESSION}" \
			-H "Content-Type: text/csv; charset=UTF-8" \
			--data-binary "@${uploadFile}" \
			"${INGESTURL}/${jobId}/batches"

		echo "DO YOU WANT TO CLOSE THE JOB: Yes/No"
		read closeJob
		if [[ "$closeJob" == "Yes" ]]
		then
			curl \
			-X PATCH \
			-H "Authorization:Bearer ${SESSION}" \
			-H "Content-Type: application/json" \
			-d '{
				    "state" : "UploadComplete"
				}' \
			"${INGESTURL}/${jobId}"
		fi
	elif  [[ "$1" == "closejob" ]] #CloseJob
	then
		echo "ENTER THE JOB ID THAT YOU WANT TO CLOSE:"
		read jobId

		curl \
		-X PATCH \
		-H "Authorization:Bearer ${SESSION}" \
		-H "Content-Type: application/json" \
		-d '{
			    "state" : "UploadComplete"
			}' \
		"${INGESTURL}/${jobId}"
	elif [[ "$1" == "success" ]] #Success
	then
		if [[ ! -d "Results" ]]
		then
			mkdir "Results"
		fi
		if [[ "$SKIPJOBIDCOMMAND" == "FALSE" ]]
		then
			echo "ENTER THE JOB ID THAT YOU WANT TO GET SUCCESS RECORDS FOR:"
			read jobId
		else
			jobId="$CURRENTJOBID"
		fi
		
		echo "FETCHING SUCCESS RECORDS FOR ${jobId}"
		SUCCESSRESULTS=$(curl \
		-X GET \
		-H "Authorization:Bearer ${SESSION}" \
		-H "Content-Type: text/csv; charset=UTF-8" \
		"${INGESTURL}/${jobId}/successfulResults/")
		echo "$SUCCESSRESULTS" > "Results/${jobId}_success.csv"
		echo "Success Records Saved in ${jobId}_success.csv"

	elif [[ "$1" == "failure" ]] #Failure
	then
		if [[ ! -d "Results" ]]
		then
			mkdir "Results"
		fi
		if [[ "$SKIPJOBIDCOMMAND" == "FALSE" ]]
		then
			echo "ENTER THE JOB ID THAT YOU WANT TO GET FAILED RECORDS FOR:"
			read jobId
		else
			jobId="$CURRENTJOBID"
		fi
		echo "FETCHING FAILED RECORDS FOR ${jobId}"
		FAILEDRESULTS=$(curl \
		-X GET \
		-H "Authorization:Bearer ${SESSION}" \
		-H "Content-Type: text/csv; charset=UTF-8" \
		"${INGESTURL}/${jobId}/failedResults/")

		echo "FAILED RESULTS : ${FAILEDRESULTS}"
		echo "$FAILEDRESULTS" > "Results/${jobId}_failed.csv"
		echo "Failed Records Saved in ${jobId}_failed.csv"
	elif [[ "$1" == "unprocessed" ]] #Unprocessed
	then
		if [[ ! -d "Results" ]]
		then
			mkdir "Results"
		fi
		if [[ "$SKIPJOBIDCOMMAND" == "FALSE" ]]
		then
			echo "ENTER THE JOB ID THAT YOU WANT TO GET UNPROCESSED RECORDS FOR:"
			read jobId
		else
			jobId="$CURRENTJOBID"
		fi
		echo "FETCHING UNPROCESSED RECORDS FOR ${jobId}"
		UNPROCESSEDRECORDS=$(curl \
		-X GET \
		-H "Authorization:Bearer ${SESSION}" \
		-H "Content-Type: text/csv; charset=UTF-8" \
		"${INGESTURL}/${jobId}/unprocessedrecords/")
		
		echo "FAILED RESULTS : ${FAILEDRESULTS}"
		echo "$UNPROCESSEDRECORDS" > "Results/${jobId}_unprocessed.csv"
		echo "Unprocessed Records Saved in ${jobId}_unprocessed.csv"
	else
		echo "The entered Command is not Valid, Choose one from these ${VALIDCOMMANDS}"
	fi
	#
}

nextCommand=""
while [ "$nextCommand" != "exit" ]
do
	echo "ENTER A COMMAND ( ACCEPTED VALUES : ${VALIDCOMMANDS})"
	read nextCommand
	echo "$nextCommand"
	if [[ "$nextCommand" == "create" ]]
	then
		echo "ENTER WHAT TYPE OF JOB TO BE CREATED: (ex: insert,update,delete)"
		read createCommand
		echo "ENTER OBJECT NAME:"
		read objName
		runJob "create" "${createCommand}" "${objName}"
	elif [[ "$nextCommand" == "results" ]]
	then
		SKIPJOBIDCOMMAND="TRUE"
		echo "ENTER THE JOB ID YOU WANT RESULTS FOR:"
		read jobId
		CURRENTJOBID="$jobId"
		runJob "success"
		runJob "failure"
		runJob "unprocessed"
		SKIPJOBIDCOMMAND="FALSE"
	else
		runJob "$nextCommand"
	fi
done