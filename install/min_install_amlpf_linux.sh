#! /bin/bash
# Copyright (C) Microsoft Corporation. All rights reserved
# Install the latest version of the AML Package for Forecasting  from Azure Storage
# To run,
# $./min_install_amlpf_linux.sh [--dsvm] [-help]
#
###############################################################################
### Define a few variables that help govern the code

STORAGE_ACCOUNT=azuremlftkrelease
RELEASE=latest
STORAGE_PREFIX=samples
# AMLPF_ENV_NAME=azuremlftk_jul2018
REQUIREMENTS=requirements_min_linux.yml

AMLPF_REQ_FILE_LOC=https://${STORAGE_ACCOUNT}.blob.core.windows.net/${RELEASE}/${REQUIREMENTS}

UBUNTU="ubuntu"
RED_HAT="red_hat"
OS=""
CONDA_MAINVERSION=4
CONDA_SUBVERSION=5
CONDA_BASE_ENV='base'         # This was changed to 'base' in the current conda distribution
                              # Use this value to indicate a non-dsvm install. 

PYTHON_MAINVERSION=3
PYTHON_SUBVERSION=6

###############################################################################
print_usage(){
    printf "Usage:    ${0} [-n] [-d] [-h]

    This script installs the AML Package for Forecasting using conda.
    The default is to create a new environment called (${AMLPF_ENV_NAME}).

    Options: 
    
         --noclone | -n  Install the Package into the base conda environment (much faster).

         --dsvm |    -d  Assume versions found on the data science virtual machine.

         --help |    -h  Print this message and exit.\n\n"
}

conda_version_check() {
    # Is there a current conda environment? 
    if ! hash conda 2>/dev/null; then
        wget -q "https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh"
        bash "Miniconda3-latest-Linux-x86_64.sh" -b
        sudo conda update conda
    else
	    # Check the version
	    CONDA_VERSION=$(conda --version 2>&1)        # Output is to stdout.
	    VERSION_NO=${CONDA_VERSION/conda /}
	    MAJOR_VERSION=${VERSION_NO:0:1}
	    MINOR_VERSION=${VERSION_NO:2:1}
	    if (( MAJOR_VERSION >= CONDA_MAINVERSION )) && ((  MINOR_VERSION >= CONDA_SUBVERSION )); then 
	         DEFAULT_ENV_NAME=CONDA_BASE_ENV
	         printf "The install will use your current conda version $VERSION_NO.\n"
	    else
	        sudo conda update conda
	    fi
    fi
}

python_version_check() {
    # Check python version.
    # Pull all digits from the string
    PYTHON_VERSION=$(python --version 2>&1 | egrep -o '[0-9]')
    PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -f 1 -d ' ')
    PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -f 2 -d ' ')
    if (( PYTHON_MAJOR == PYTHON_MAINVERSION )) && (( PYTHON_MINOR == PYTHON_SUBVERSION )); then
	CONDA_BASE_ENV=base
    else
	printf "Please upgrade to python v${PYTHON_MAINVERSION}.${PYTHON_SUBVERSION}.\n"
    fi
}

##########################################################################
#Set clone root environment to true if not said otherwise.
CLONE_ROOT_ENVIRONMENT=0

if [ $# -gt 0 ]; then
  #If there are command line parameters, check there values.
  case $1 in
     --dsvm | -d)
	 # Bypass version checking, assume a dsvm
	 CONDA_BASE_ENV='py35'
         #Do not clone the environment.
         unset CLONE_ROOT_ENVIRONMENT
	 ;;
     --help | -h)
         print_usage
         exit 0
         ;;
     *)
         printf "Error: Unknown option ${1}\n"
         print_usage
         exit 1
         ;;
  esac
fi

conda_version_check

if [ ${CONDA_BASE_ENV} == base ]; then
    python_version_check
fi
    
# Make sure we start in the base conda env, if not there already
source activate ${CONDA_BASE_ENV}
#checking for presence of python v3 in the path
PYTHON_PATH="`which python`"
if [ -e $PYTHON_PATH  ]; then
    CONDA_BASE_PATH="`dirname $PYTHON_PATH`/"
    printf "$CONDA_BASE_PATH will be used as the conda install path.\n"
else
    printf "
    Error: Did not find a python distribution.
    Please check that the anaconda environment is in your path.\n"
fi

# Check if there's at least 10G space to create a new environment
CONDA_FILESYSTEM_SPACE=$(df --output=avail $CONDA_BASE_PATH | sed -n '2{p}')
if [ ${CLONE_ROOT_ENVIRONMENT} ]; then
    # available space in 1K blocks
    if (( CONDA_FILESYSTEM_SPACE <  10000000)); then         # hack for 'is true'
	printf "Only $CONDA_FILESYSTEM_SPACE kB available on $CONDA_BASE_PATH. That might not be enough space.\n"
    else
	printf "  $CONDA_FILESYSTEM_SPACE kB available on $CONDA_BASE_PATH.\n"
    fi
fi

# Activate the target conda environment
source activate ${AMLPF_ENV_NAME}

# Update env with AMLPF and its dependencies
printf "
================================================================
Installing Azure ML Package for Forecasting into the environment   
================================================================\n"
wget  -q ${AMLPF_REQ_FILE_LOC} -O ${REQUIREMENTS}

if [ "$OS" == "$UBUNTU" ]; then
    sudo ${CONDA_BASE_PATH}conda env update --file requirements_linux.yml -n ${AMLPF_ENV_NAME}
    # ipykernel should be present already, but we want to be safe
    sudo ${CONDA_BASE_PATH}conda install -y ipykernel -n ${AMLPF_ENV_NAME}
else
    #We have incompatible version of numpy installed. Delete it and run.
    ${CONDA_BASE_PATH}conda remove numpy --yes -n ${AMLPF_ENV_NAME}
    #Not using sudo for red_hat/centos
    ${CONDA_BASE_PATH}conda env update --file requirements_linux.yml -n ${AMLPF_ENV_NAME}
    # ipykernel should be present already, but we want to be safe
    ${CONDA_BASE_PATH}conda install -y ipykernel -n ${AMLPF_ENV_NAME}
fi

# register new ipython kernel 
# Use ipython within the current conda env
IPY_PATH_IN_AML_ENV=`which ipython`
sudo ${IPY_PATH_IN_AML_ENV} kernel install --name ${AMLPF_ENV_NAME} --display-name "${AMLPF_ENV_NAME}"

exit 0
