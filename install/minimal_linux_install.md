# steps to create a minimal ubuntu install of FTK

## Use the package list from the current DSVM for the py35 conda env
## generated with 
## $ source activate py35
## $ conda list --explicit > py35_explicit.txt
## Note, this might be more packages than necessary

$ conda create --name py35 --file py35_explicit.txt

# Check for necessary versions - and install the latest FTK wheel 

$ conda env update --file requirements_min_linux.yml

# OK - now go to a notebooks directory and run

$ jupyter lab


