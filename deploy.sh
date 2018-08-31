#!/bin/bash
# deploy.sh
# 28 Aug 2018 JMA
# Invoke an Azure Resource Manager (ARM) template to create a VM
# using local bash 'az' commands. 
#
# The inverse - to remove the VM is best done by deleting its unique resource group:
# $ az group delete --name myResourceGroup

set -euo pipefail
IFS=$'\n\t'

# -e: immediately exit if any command has a non-zero exit status
# -o: prevents errors in a pipeline from being masked
# IFS new value is less likely to cause confusing bugs when looping arrays or arguments (e.g. $@)

usage() { echo "Usage: $0 [-d] [-h] [-n <deploymentName> ]" 1>&2; exit 1; }

# Date string "year.dayofyear.hour" e.g. 18.243.10
date_string=$(date +'%y.%j.%k')

# Create a unique default deployment name, used to track the task in the Portal
declare deploymentName="VM_dply_$date_string"

declare subscriptionId=""
declare resourceGroupName=""
declare resourceGroupLocation=""
source secrets.sh


#templateFile Path - template file to be used
declare templateFilePath="template.json"

#parameter file path
declare parametersFilePath="parameters.json"

# Deploy instead of just validate
validate=0


# Initialize parameters specified from command line, if specified. 
while getopts ":dhn:" arg; do
	case "${arg}" in
		d)
			validate=1	
			;;
		n)
			deploymentName=${OPTARG}
			;;
		h)
			printf "$0:
        -d:                    Validate template.json
        -n  <DeploymentName>:  Name for VM\n\n"
			exit 1
			;;
		\?)
			printf "Invalid option -$OPTARG\n"
			usage
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

if [ -z "$subscriptionId" ]; then
	echo "SubscriptionId is empty"
	usage
else
	echo "SubscriptionId is $subscriptionId ."
fi

if [ -z "$resourceGroupName" ]; then
	echo "ResourceGroupName is empty"
	usage
else
	echo "ResourceGroupName is $resourceGroupName ."
fi

if [ -z "$deploymentName" ]; then
	echo "DeploymentName is empty"
	usage
else
	echo "DeploymentName is $deploymentName"
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
az group show --name $resourceGroupName 1> /dev/null

if [ $? != 0 ]; then
	echo "Resource group with name" $resourceGroupName "could not be found. Creating new resource group.."
	set -e
	(
		set -x
		az group create --name $resourceGroupName --location $resourceGroupLocation 1> /dev/null
		# Note, if creating a new resource group, a new virtual network is needed e.g. 
		# az network vnet create -g dlnn18829 --name dlnn18829-vnet --subnet-name Subnet
	)
	else
	echo "Using existing resource group..."
fi

#Start deployment
if [ $validate = 1 ]; then
    printf "Validating deployment...\n"
		# Validate does not take a --name arg
	az group deployment validate --resource-group "$resourceGroupName" \
	--template-file "$templateFilePath" \
	--parameters "@${parametersFilePath}"
	if [ $?  == 0 ];
 	then
		echo "Template has been successfully validated."
	fi
else
    printf "Starting deployment...\n"
    (
	set -x
	az group deployment create --name "$deploymentName" \
	   --resource-group "$resourceGroupName" \
	   --template-file "$templateFilePath" \
	   --parameters "@${parametersFilePath}"
    )
	if [ $?  == 0 ];
 	then
		echo "Template has been successfully deployed."
	fi
fi

