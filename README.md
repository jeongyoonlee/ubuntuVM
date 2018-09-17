# A one-step customized ubuntuVM
Example of an ARM script to configure and deploy an Ubuntu VM on Azure from a local machine. In this
example we load the Forecasting Package to customize the VM. 

## Minimal Install
Here's the end-to-end minimal install idea:  

``` Deploy local shell script in github ->
        “az group deployment create   … “ ->
        template.json for VM and related resources
    which invokes a config shell script on the newly created VM
    which loads a docker container with PF installed. 
```

The endpoint is one command  that completes with a running VM with PF pre-installed, much like the DSVM comes with tools pre-installed (possibly we do this on top of the DSVM).  


### Technicalities

The ARM template requires a URI for the config file to be run on the VM, which should be provided by this repo.  This can be done using a permanent link to the file in github.  This is created in github by browsing to the file, displaying the raw version, then pressing "y" as a shortcut to convert the link shown in the browser to a `permalink.`  _I bet you din't know that._  

A couple options are contained in the `template.json` file and not exposed in the deploy options. Making changes require editing template files, possibly generating new template files from the Portal. 

#### DSVM or just plain ubuntu?

The choice of the product is embedded here, for the DSVM:

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

The templates push a shell script via this extension. Here's where the name of the script can be changed.  Search for it under resources:

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


