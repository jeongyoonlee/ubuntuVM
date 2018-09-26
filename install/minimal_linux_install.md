# steps to create a minimal ubuntu install of FTK

## Use the package list from the current DSVM for the py35 conda env
## generated with 
## $ source activate py35
## $ conda list --explicit > py35_explicit.txt
## Note, this might be more packages than necessary

$ conda create --name py35 --file py35_explicit.txt

# Check for necessary versions - and install the latest FTK wheel 

$ conda env update --file requirements_min_linux.yml --name py35

To force a downgrade to python 3.5.2 one uses 

$ conda env update   --file requirements.yml –name py35

It ignores the 

`name: azuremlftk_july2018  ` 

from the requirements.yml file.

Note: If you leave the “name” line in the requirements.yml file, ` conda env update` applies to that environment and if one doesn’t exist it creates one like `conda env create.`   I don’t find where this is documented in the conda documentation.   I suppose “update” and “create” work the same, taking the name of environment to be modified from the requirements file, as the default and overriding it if the name is specified on the command line. 

# OK - now go to a notebooks directory and run

$ jupyter lab


