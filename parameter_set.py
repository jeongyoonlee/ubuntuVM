#!/bin/python
# 31 Aug 2018 JMA
# parameter_set.py  
# Set the parameters in the template parameters file to match the custom VM name
import os, sys, json

PARAM_FILE = "parameters.json"

# script variables, passed as command line arguments
if len(sys.argv <= 5 ):
    print("Missing all 5 variables", file=sys.stderr)
else:
    virtualMachineName = sys.argv[1]
    resourceGroupName = sys.argv[2] 
    userName = sys.argv[3] 
    subscriptionId = sys.argv[4] 
    resourceGroupLocation = sys.argv[5] 


# Set corresponding json fields
jp = json.load(open("parameters.json"))
params = jp["parameters"]
params["location"]["value"] = resourceGroupLocation
params["resourceGroupName"]["value"] = resourceGroupName
params["virtualMachineName"]["value"] = virtualMachineName
params["adminUsername"]["value"] = userName
params["virtualNetworkName"]["value"] = resourceGroupName + "-vnet"
params["networkInterfaceName"]["value"] = resourceGroupName + "-nin"
params["networkSecurityGroupName"]["value"] = resourceGroupName + "-nsg"
params["diagnosticsStorageAccountName"]["value"] = resourceGroupName + "-dsa"
params["publicIpAddressName"]["value"] = resourceGroupName + "-pip"
#params["diagnosticsStorageAccountId"]["value"] = 

# Assume ssh keys exist for this account. 
ssh_key  = open(os.path.join())

jp.close()

# The customized file
json.dumps(open(PARAM_FILE))

#EOF