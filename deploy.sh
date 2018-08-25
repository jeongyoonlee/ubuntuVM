#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# -e: immediately exit if any command has a non-zero exit status
# -o: prevents errors in a pipeline from being masked
# IFS new value is less likely to cause confusing bugs when looping arrays or arguments (e.g. $@)

usage() { echo "Usage: $0 -i <subscriptionId> -g <resourceGroupName> -n <deploymentName> -l <resourceGroupLocation>" 1>&2; exit 1; }

declare subscription=""
declare resourceGroupName=""
declare deploymentName=""
declare resourceGroupLocation=""
source secrets.sh


#templateFile Path - template file to be used
declare templateFilePath="template.json"

#parameter file path
declare parametersFilePath="parameters.json"

# Validate only
validate=1


# Initialize parameters specified from command line, if specified. 
while getopts ":i:g:n:l:" arg; do
	case "${arg}" in
		i)
			subscriptionId=${OPTARG}
			;;
		g)
			resourceGroupName=${OPTARG}
			;;
		n)
			deploymentName=${OPTARG}
			;;
		l)
			resourceGroupLocation=${OPTARG}
			;;
		esac
done
shift $((OPTIND-1))

if [ ! -f "$templateFilePath" ]; then
	echo "$templateFilePath not found"
	exit 1
fi

if [ ! -f "$parametersFilePath" ]; then
	echo "$parametersFilePath not found"
	exit 1
fi

if [ -z "$subscriptionId" ] || [ -z "$resourceGroupName" ] || [ -z "$deploymentName" ]; then
	echo "Either one of subscriptionId, resourceGroupName, deploymentName is empty"
	usage
fi

#login to azure using your credentials
az account show 1> /dev/null

if [ $? != 0 ];
then
	az login
fi

#set the default subscription id
az account set --subscription $subscriptionId

set +e

#Check for existing RG
az group show $resourceGroupName 1> /dev/null

if [ $? != 0 ]; then
	echo "Resource group with name" $resourceGroupName "could not be found. Creating new resource group.."
	set -e
	(
		set -x
		az group create --name $resourceGroupName --location $resourceGroupLocation 1> /dev/null
	)
	else
	echo "Using existing resource group..."
fi

#Start deployment
if [ $validate = 1 ]; then
    printf "Validating deployment...\n"
    az group deployment validate --resource-group "$resourceGroupName" \
	--template-file "$templateFilePath" \
	--parameters "@${parametersFilePath}"
else
    printf "Starting deployment...\n"
    (
	set -x
	az group deployment create --name "$deploymentName" \
	   --resource-group "$resourceGroupName" \
	   --template-file "$templateFilePath" \
	   --parameters "@${parametersFilePath}"
    )
fi

if [ $?  == 0 ];
 then
	echo "Template has been successfully deployed"
fi
