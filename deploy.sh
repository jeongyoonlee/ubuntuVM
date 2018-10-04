#!/bin/bash
# deploy.sh
# 28 Aug 2018 JMA
# Invoke an Azure Resource Manager (ARM) template to create a VM
# using local bash 'az' commands.  This is the entry point for the process
#
# From a local bash shell (e.g. Once you download the repo), run this as
# $ bash deploy.sh
#
# The inverse - to remove the VM is best done by deleting its unique resource group
# with this command:
# $ az group delete --name myResourceGroup

set -euo pipefail
IFS=$'\n\t'

# -e: immediately exit if any command has a non-zero exit status
# -o: prevents errors in a pipeline from being masked
# IFS new value is less likely to cause confusing bugs when looping arrays or arguments (e.g. $@)

usage() { echo "Usage: $0 [-d] [-m] [-h] [-n <VMprefix> ]" 1>&2; exit 1; }

# Date string "year.dayofyear.hour" e.g. 18.243.10
date_string=$(date +'%y.%j.%H')

# Create a unique default deployment name, used to track the task in the Portal
# (could be cmd line options)
declare virtualMachineName="fpvm$(date +'%y%j%H')"
declare deploymentName="$virtualMachineName"
declare resourceGroupName="fprg_$date_string"
# Use the local as a default
declare userName=$USER
# Load these from a separate file
declare subscriptionId=""
declare resourceGroupLocation=""
source secrets.sh

#templateFile Path - template file to be used
declare templateFilePath="vm_template.json"

#parameter file path
declare parametersFilePath="parameters.json"

# Deploy instead of just validate
validate=0

# Initialize parameters specified from command line, if specified. 
while getopts ":dhn:m" arg; do
	case "${arg}" in
		d)
			validate=1
			;;
		m)
    		# Choice of the kind of VM to use.
		    templateFilePath="dsvm_template.json"
			;;
		n)
			deploymentName="${OPTARG}$(date +'%y%j%H')"
			;;
		h)
			printf "$0:
        -d                     Validate template.json
	-m                     Not just a VM, but a DSVM
        -n  <DeploymentName>:  Name for both deployment and the VM\n\n"
			exit 1
			;;
		\?)
			printf "Invalid option -$OPTARG\n"
			usage
		esac
done
shift $((OPTIND-1))

if [ -z "$virtualMachineName" ]; then
	echo "$virtualMachineName not found"
	exit 1
else
	printf "Will create VM $virtualMachineName.\n"
fi

if [ ! -f "$templateFilePath" ]; then
	echo "$templateFilePath not found"
	exit 1
fi

if [ -z "$subscriptionId" ]; then
	echo "SubscriptionId is empty"
	usage
else
	echo "SubscriptionId is $subscriptionId "
fi

if [ -z "$resourceGroupName" ]; then
	echo "ResourceGroupName is empty"
	usage
else
	echo "ResourceGroupName is $resourceGroupName "
fi

if [ -z "$deploymentName" ]; then
	echo "DeploymentName is empty"
	usage
else
	echo "DeploymentName is $deploymentName"
fi

# Customize parameters json file by substituting into parameters.json
./parameter_set.py ${virtualMachineName}\
	${resourceGroupName}\
	${userName}\
	${subscriptionId}\
	${resourceGroupLocation}

if [ ! -f "$parametersFilePath" ]; then
	echo "$parametersFilePath not found"
	exit 1
fi

# Customize config.sh that is pushed to the VM
# ./config_set.py ${userName}



#login to azure using your credentials
az account show 1> /dev/null

if [ $? != 0 ];
then
	az login
fi

#set the default subscription id
az account set --subscription $subscriptionId 1> /dev/null

set +e

#Check for existing RG
group_exists=$(az group exists --name $resourceGroupName)

if [ $group_exists == 'false' ]; then
	echo "Resource group with name" $resourceGroupName "could not be found. Creating new resource group.."
	set -e
	(
		set -x
		az group create --name $resourceGroupName --location $resourceGroupLocation 1> /dev/null
		# Note, if creating a new resource group, a new virtual network is needed e.g. 
		az network vnet create -g $resourceGroupName --name "${resourceGroupName}-vnet" --subnet-name Subnet 1> /dev/null
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
		echo "Template has been validated."
	fi
else
    printf "Starting deployment...\n"
    (
	set -x
	az group deployment create --name "$deploymentName" \
	   --resource-group "$resourceGroupName" \
	   --template-file "$templateFilePath" \
	   --parameters "@${parametersFilePath}"  1> /dev/null
    )
	if [ $?  == 0 ];
 	then
		echo "Template has been successfully deployed."
		az vm list-ip-addresses -g "$resourceGroupName" -n  "$virtualMachineName"
	fi
fi

