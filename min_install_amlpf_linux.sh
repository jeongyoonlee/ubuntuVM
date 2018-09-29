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
REQUIREMENTS=requirements_linux.yml

AMLPF_REQ_FILE_LOC=https://${STORAGE_ACCOUNT}.blob.core.windows.net/${RELEASE}/${REQUIREMENTS}

UBUNTU="ubuntu"
OS=""
CONDA_MAINVERSION=4
CONDA_SUBVERSION=5
CONDA_BASE_ENV='base'         # This was changed to 'base' in the current conda distribution
                              # Use this value to indicate a non-dsvm install. 

PYTHON_MAINVERSION=3
PYTHON_SUBVERSION=5

conda_version_check() {
    # Is there a current conda environment? 
    if ! hash conda 2>/dev/null; then
        printf "Installing conda.\n"
        sudo apt update --yes
        sudo apt upgrade --yes
        # Get Miniconda and make it the main Python interpreter
        wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh
        bash ~/miniconda.sh -b -p ~/miniconda 
        rm ~/miniconda.sh
        echo "PATH=\$PATH:\$HOME/miniconda/bin" >> .bashrc
    fi

    # Check the version (might not be needed)
    # CONDA_VERSION=$(conda --version 2>&1)        # Output is to stdout.
    # VERSION_NO=${CONDA_VERSION/conda /}
    # MAJOR_VERSION=${VERSION_NO:0:1}
    # MINOR_VERSION=${VERSION_NO:2:1}
    # if (( MAJOR_VERSION >= CONDA_MAINVERSION )) && ((  MINOR_VERSION >= CONDA_SUBVERSION )); then 
    #         Note: upgrading conda in the base env makes it available in all other envs. 
    #         DEFAULT_ENV_NAME=CONDA_BASE_ENV
    #         printf "The install will use your current conda version $VERSION_NO.\n"
    # fi
    # # cond
    # conda update -n base -c defaults conda

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

free_space_check() {
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
}

##########################################################################
# MAIN ############# 
set -x
if !apt-get 2>/dev/null; then  #not ubuntu
    printf "This script only runs on Ubuntu\n"
    exit 1
else
    printf "Running as id: $(id)\n"
fi

conda_version_check

if [ -n "${VM_OFFER}" ]; then
    CONDA_BASE_ENV='py35'
else
    # Add things needed in the DSVM
   printf "We are on plain ubuntu, install mono\n"
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
    echo "deb http://download.mono-project.com/repo/ubuntu stable-xenial main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list
    sudo apt-get update
    sudo apt-get -y install mono-complete
    OS=${UBUNTU}
    printf "Create conda env $CONDA_BASE_ENV\n"
    # Vanilla ubuntu conda install was done in conda_version_check()
    conda create --name py35 --file py35_explicit.txt
    CONDA_BASE_ENV='py35'
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

# Activate the target conda environment
source activate ${CONDA_BASE_ENV}

# Update env with AMLPF and its dependencies
printf "
================================================================
Installing Azure ML Package for Forecasting into the environment   
================================================================\n"
wget  -q ${AMLPF_REQ_FILE_LOC} -O ${REQUIREMENTS}

sudo ${CONDA_BASE_PATH}conda env update --file ${REQUIREMENTS} -n ${CONDA_BASE_ENV}
    # ipykernel should be present already, but we want to be safe
#     sudo ${CONDA_BASE_PATH}conda install -y ipykernel -n ${CONDA_BASE_ENV}}

# register new ipython kernel 
# Use ipython within the current conda env
IPY_PATH_IN_AML_ENV=`which ipython`
sudo ${IPY_PATH_IN_AML_ENV} kernel install --name ${CONDA_BASE_ENV} --display-name "${CONDA_BASE_ENV}"

set +x
exit 0
