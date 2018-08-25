#!/bin/bash
# 19 July 2018 JMA
# Things to do to customize an Ubuntu VM

# Check if this is a DSVM
# The command will fail if not an Azure VM 
curl -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-08-01" | \
    python -m json.tool | \
    tee vm_properties.json
