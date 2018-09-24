#!/usr/bin/env python3
# 31 Aug 2018 JMA
# parameter_set.py  
# Set the parameters in the template parameters file to match the custom VM name
import os, os.path, sys, json

PARAM_INPUT_FILE = "proto_parameters.json"
PARAM_FILE = "parameters.json"

# perhaps promote to cmd line args
VM_SKU= 'Standard_B2s'

# Assume ssh keys exist for this account. 
# Note that ~ expansion on WSL is not consistent
def ssh_key_str():
    try:
        key_fd = open(os.path.expanduser('~/.ssh/id_rsa.pub'))
        return key_fd.read()
    except:
        "No id_rsa.pub key found.  Please generate an ssh key"
        return ''

# script variables, passed as command line arguments
if len(sys.argv) <= 5 :
    print("Missing 5 variables", file=sys.stderr)
    exit(1)
else:
    virtualMachineName = sys.argv[1]
    resourceGroupName = sys.argv[2] 
    userName = sys.argv[3] 
    subscriptionId = sys.argv[4] 
    resourceGroupLocation = sys.argv[5] 

# Set corresponding json fields
proto_params_fd = open(PARAM_INPUT_FILE)
jp = json.load(proto_params_fd) 
proto_params_fd.close()

params = jp["parameters"]
params["location"]["value"] = resourceGroupLocation
params["resourceGroupName"]["value"] = resourceGroupName
params["virtualMachineName"]["value"] = virtualMachineName
params["adminUsername"]["value"] = userName
params["adminPublicKey"]["value"] = ssh_key_str()
params["virtualNetworkName"]["value"] = resourceGroupName + "-vnet"
params["networkInterfaceName"]["value"] = resourceGroupName + "-nin"
params["networkSecurityGroupName"]["value"] = resourceGroupName + "-nsg"
# params["diagnosticsStorageAccountName"]["value"] = resourceGroupName + "-dsa"
params["publicIpAddressName"]["value"] = resourceGroupName + "-ip"
### Instead we select DSVM by choice of template.json file in deploy.sh
# if use_dsvm:
#     params["virtualMachineSize"]["value"] = VANILLA_VM
# else:
#     params["virtualMachineSize"]["value"] = DSVM

# Insert params into the full parameters file
jp["parameters"] = params

# The customized file

open(PARAM_FILE, 'w').write(json.dumps(jp, indent=4))
print("Wrote new {} file".format(PARAM_FILE), file=sys.stderr)

#EOF
