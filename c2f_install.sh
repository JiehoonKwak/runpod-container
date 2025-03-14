#!/bin/bash
set -e

# Download Miniconda
echo "Downloading Miniconda..."
wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh

# Install Miniconda silently
echo "Installing Miniconda..."
bash Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda3

# Set up conda in path for this script
export PATH="$HOME/miniconda3/bin:$PATH"

# Initialize conda for bash (creates .bashrc modifications)
echo "Initializing conda..."
$HOME/miniconda3/bin/conda init bash

# Source bashrc to make conda available in this script
source ~/.bashrc || source $HOME/.bashrc

# Create and activate the cell2fate environment
echo "Creating cell2fate environment..."
$HOME/miniconda3/bin/conda create -y -n cell2fate_env python=3.9

# Need to use conda's shell hook to activate environment in script
eval "$($HOME/miniconda3/bin/conda shell.bash hook)"
conda activate cell2fate_env

# Install cell2fate and its dependencies
echo "Installing cell2fate and dependencies..."
pip install git+https://github.com/BayraktarLab/cell2fate
pip install ipykernel

# Set up Jupyter kernel
echo "Setting up Jupyter kernel..."
python -m ipykernel install --user --name=cell2fate_env --display-name='Environment (cell2fate_env)'

echo "Setup complete! You can activate the environment with: conda activate cell2fate_env"