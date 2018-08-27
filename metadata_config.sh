#!/bin/bash
# 19 July 2018 JMA
# Things to do to customize an Ubuntu VM

# Check if this is a DSVM

# Is the json parser for bash installed
if ! hash jq 2>/dev/null; then
    sudo apt-get -y install jq
fi

#Given the install succeeded
if hash jq 2>/dev/null; then
    METADATA=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-08-01" )
    if [ $? = 0 ]; then       # curl succeeded, we are on a VM
	echo $METADATA | jq .  > vm_properties.json
	VM_OFFER=$(echo $METADATA | jq .compute.offer)
	VM_VERSION=$(echo $METADATA | jq .compute.version)
	printf 'VM: %s, %s\n' $VM_OFFER $VM_VERSION
    fi
fi

#TODO append variables to .bashrc file
 
    
