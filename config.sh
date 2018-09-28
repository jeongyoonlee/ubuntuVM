#!/bin/bash
# 5 Sept 2018 JMA
# Things to do to customize an Ubuntu VM

# This file runs with waagent permissions
# You will find it uploaded to
# /var/lib/waagent/Microsoft.OSTCExtensions.CustomScriptForLinux-1.5.3/download
# along with its errout and stdout

VMUSER=$1
cd /home/${VMUSER}
# Bring in subsidiary files:
curl -O "https://raw.githubusercontent.com/jmagosta/ubuntuVM/master/py35_explicit.txt" 
# curl -O "https://github.com/jmagosta/ubuntuVM/blob/master/install/requirements_min_linux.yml" Download this in the install script. 
curl -O "https://raw.githubusercontent.com/jmagosta/ubuntuVM/master/min_install_amlpf_linux.sh"

# The json parser for bash? Install if missing
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
    else
        echo "No metadata: $METADATA"
    fi
else
    echo "No jq interpreter found."
fi

chown -R ${VMUSER} * 
# Append variables to .bashrc file
printf "export VM_OFFER=${VM_OFFER}\nexport VM_VERSION=${VM_VERSION}\n" >> /home/${VMUSER}/.bashrc
# (This doesn't do what's intended.)
source .bashrc

# Now install fp at user level
chmod +x "/home/${VMUSER}/min_install_amlpf_linux.sh"
sudo -u ${VMUSER}  bash "/home/${VMUSER}/min_install_amlpf_linux.sh"
