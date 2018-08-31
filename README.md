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

