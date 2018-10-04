# A one-step customized ubuntuVM

Example of an ARM script to configure and deploy an Ubuntu VM on Azure from a local machine. In this
example we load the Forecasting Package to customize the VM. 

## Minimal Install
 An end-to-end minimal install consists of   

* Deploy local shell script in github 
* that runs `az group deployment create   … `
* using  a `template.json` file to create VM and related resources
* which invokes a config shell script on the newly created VM
* which can install, for instance, the Forecast Package.

The user executes one command that completes with a running VM with PF pre-installed, much like the DSVM comes with tools pre-installed. There are options to create either a fresh ubuntu VM or creating it on top of the DSVM.  

These scripts invoke [Azure CLI 2](https://docs.microsoft.com/en-us/cli/azure/?view=azure-cli-latest) commands that take [ARM](https://docs.microsoft.com/en-us/rest/api/resources) template files that describe what to create.

### Prerequisites

You will need an Azure subscription and an Azure location where the resources will be created. Edit the file called `secrets.sh` to specify them. The file looks like this:

```
declare resourceGroupLocation="West US 2"
declare subscriptionId="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXX"
```

You also need a SSH public key on the system where you execute the command. If you haven't, you can create an SSH key pair as follows:
```bash
$ ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/home/$USER/.ssh/id_rsa): <Enter>
Enter passphrase (empty for no passphrase): <Enter>
Enter same passphrase again: <Enter>
Your identification has been saved in /home/$USER/.ssh/id_rsa.
Your public key has been saved in /home/$USER/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:xxx... $USER@$HOSTNAME
The key's randomart image is:
+---[RSA 2048]----+
...
+----[SHA256]-----+
```

### Technicalities

The ARM template requires a URI for the config shell script to be run on the VM, which is provided by this repo.  This is done using a permanent link to the file in github.  This is created in github by browsing to the file, displaying the raw version, then pressing "y" as a shortcut to convert the link shown in the browser to a `permalink.`  _I bet you didn't know that._  i

#
### Resource group creation

A new resource group is created when the template is validated (by `./deploy.sh -d`) whose name is derived from the current hour-timestamp. This assures that resource creation is possible before running the full deployment. This resource group will then be used by the deployment.  If the deployment is not completed, or if it is attempted at a later time, the validation-time resource group will persist as an unused vestige. Or if two deployments are done within the hour, the second will fail due to duplicated names. 

A couple options are contained in the two `template.json` files, one for plain VMs, and one for DSVMs, and are not exposed in the deploy options. Making changes require editing template files, possibly generating new template files from the Portal. 

### DSVM or just plain ubuntu?

The choice of the product is a command line option to choose template files with different images. Here's the fragment that specifies a DSVM:

                "storageProfile": {
                    "imageReference": {
                        "publisher": "microsoft-dsvm",
                        "offer": "linux-data-science-vm-ubuntu",
                        "sku": "linuxdsvmubuntu",
                        "version": "latest"
                    },

alternately for the unbuntu VM:

                "storageProfile": {
                    "imageReference": {
                        "publisher": "Canonical",
                        "offer": "UbuntuServer",
                        "sku": "16.04-LTS",
                        "version": "latest"
                    },

#### Configuration scripts

The templates push a shell script that executes when the VM in created via this extension. Here's where the name of the script can be changed.  Search for it under resources:

		    "properties": {
			"publisher": "Microsoft.OSTCExtensions",
			"type": "CustomScriptForLinux", 
			"typeHandlerVersion": "1.5",
			"autoUpgradeMinorVersion": true,
			"settings": {
                "fileUris": ["https://raw.githubusercontent.com/jmagosta/ubuntuVM/master/config.sh" ],
			    "commandToExecute": "[concat('bash config.sh ', parameters('adminUsername'))]"
			    }
		    }

#### Machine Size

This parameter is hard-wired into the `proto_parameters.json` file. 

        "virtualMachineSize": {
            "value":  "Standard_D4s_v3" 
        },

Before you change this value note that the DSVM does not support all VM sizes, and the VM images differ in different regions. Some smaller sizes do not support the premium storage expected by the DSVM. 


#### Storage blob for diagnostics

The template assumes there is an existing storage blob available for VM diagnostics.  This blob may be reused for many VMs and doesn't have to be in the same resource group as the VM.  You would need to reference it in this part of the template. If such a blob is not available, you disable it, but setting "enabled" to `false`, like this:

                "diagnosticsProfile": {
                    "bootDiagnostics": {
                        "enabled": false,
                        "storageUri": "[concat('https://', parameters('diagnosticsStorageAccountName'), '.blob.core.windows.net/')]"
                    }
                }




