#!/bin/bash

: '
    Copyright (C) 2021 IBM Corporation
    Rafael Sene <rpsene@br.ibm.com> - Initial implementation.
'

# Trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
    echo "Bye!"
    exit 0
}

function check_dependencies() {

    DEPENDENCIES=(ibmcloud curl sh wget jq)
    check_connectivity
    for i in "${DEPENDENCIES[@]}"
    do
        if ! command -v "$i" &> /dev/null; then
            echo "$i could not be found, exiting!"
            exit
        fi
    done
}

function check_connectivity() {

    if ! curl --output /dev/null --silent --head --fail http://cloud.ibm.com; then
        echo "ERROR: please, check your internet connection."
        exit 1
    fi
}

function authenticate() {

    local APY_KEY="$1"

    if [ -z "$APY_KEY" ]; then
        echo "API KEY was not set."
        exit
    fi
    ibmcloud login --no-region --apikey "$APY_KEY" > /dev/null 2>&1
}

function get_all_crn(){
    TODAY=$(date '+%Y%m%d')
	rm -f /tmp/crns-"$TODAY"
	ibmcloud pi service-list --json | jq -r '.[] | "\(.CRN),\(.Name)"' >> /tmp/crns-"$TODAY"
}

function set_powervs() {

    local CRN="$1"
    if [ -z "$CRN" ]; then
        echo "CRN was not set."
        exit
    fi
    ibmcloud pi st "$CRN" > /dev/null 2>&1
}

function image_age() {

    TODAY=$(date '+%Y%m%d')
    rm -f /tmp/images-"$TODAY"
	PVS_NAME=$1
	IBMCLOUD_ID=$2
	IBMCLOUD_NAME=$3
    PVS_ZONE=$4
    POWERVS_ID=$5

    ibmcloud pi images --json | jq -r ".[] | .images" | jq -r '.[] | "\(.name),\(.imageID),\(.creationDate),\(.specifications.operatingSystem),\(.storageType)"' > "/tmp/images-$PVS_NAME-$TODAY"

    while read -r line; do
        IMAGE_NAME=$(echo "$line" | awk -F ',' '{print $1}')
        IMAGE_ID=$(echo "$line" | awk -F ',' '{print $2}')
        OS=$(echo "$line" | awk -F ',' '{print $4}')
        STORAGE_TYPE=$(echo "$line" | awk -F ',' '{print $5}')
        VM_CREATION_DATE=$(echo "$line" | awk -F ',' '{print $3}')

        Y=$(echo "$VM_CREATION_DATE" | awk -F '-' '{print $1}')
        M=$(echo "$VM_CREATION_DATE" | awk -F '-' '{print $2}' | sed 's/^0*//')
        D=$(echo "$VM_CREATION_DATE" | awk -F '-' '{print $3}' | awk -F 'T' '{print $1}' | sed 's/^0*//')
        AGE=$(python3 -c "from datetime import date as d; print(d.today() - d($Y, $M, $D))" | awk -F ',' '{print $1}')
        AGE=$(echo "$AGE" | tr -d " days")
	    if [[ "$AGE" == "0:00:00" ]]; then
		    AGE="0"
	    fi
        echo "$IBMCLOUD_ID,$IBMCLOUD_NAME,$POWERVS_ID,$PVS_NAME,$PVS_ZONE,$IMAGE_NAME,$IMAGE_ID,$OS,$STORAGE_TYPE,$AGE" >> all_images_"$TODAY".csv
    done < "/tmp/images-$PVS_NAME-$TODAY"
}

function get_images_per_crn(){
    TODAY=$(date '+%Y%m%d')
    IBMCLOUD_ID=$1
    IBMCLOUD_NAME=$2

	while read -r line; do
        CRN=$(echo "$line" | awk -F ',' '{print $1}')
        POWERVS_NAME=$(echo "$line" | awk -F ',' '{print $2}')
        POWERVS_ZONE=$(echo "$line" | awk -F ':' '{print $6}')
        POWERVS_ID=$(echo "$CRN" | awk '{split($1,ID,":"); print ID[length(ID)-2]}')
		set_powervs "$CRN"
        image_age "$POWERVS_NAME" "$IBMCLOUD_ID" "$IBMCLOUD_NAME" "$POWERVS_ZONE" "$POWERVS_ID"
	done < /tmp/crns-"$TODAY"
}

function run (){
	ACCOUNTS=()
	while IFS= read -r line; do
		clean_line=$(echo "$line" | tr -d '\r')
		ACCOUNTS+=("$clean_line")
	done < ./cloud_accounts

	for i in "${ACCOUNTS[@]}"; do
		IBMCLOUD=$(echo "$i" | awk -F "," '{print $1}')
		IBMCLOUD_ID=$(echo "$IBMCLOUD" | awk -F ":" '{print $1}')
		IBMCLOUD_NAME=$(echo "$IBMCLOUD" | awk -F ":" '{print $2}')
		API_KEY=$(echo "$i" | awk -F "," '{print $2}')

		if [ -z "$API_KEY" ]; then
		    echo
			echo "ERROR: please, set your IBM Cloud API Key."
			echo "		 e.g ./vms-age.sh API_KEY"
			echo
			exit 1
		else
			check_dependencies
			check_connectivity
			authenticate "$API_KEY"
			get_all_crn
			get_images_per_crn "$IBMCLOUD_ID" "$IBMCLOUD_NAME"
		fi
	done
    awk 'NF' ./*.csv
}

run "$@"
