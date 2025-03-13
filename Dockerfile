# Use NVIDIA CUDA base image compatible with Python 3.9
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV SHELL=/bin/bash
ENV PATH=/opt/conda/bin:/usr/local/cuda/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
ENV NVIDIA_VISIBLE_DEVICES=all
ENV CUDA_LAUNCH_BLOCKING=1

# Set the working directory
WORKDIR /

# Create workspace directory
RUN mkdir /workspace

# Set up locales
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends locales && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Update and install packages
RUN apt-get update --yes && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade --yes && \
    DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
    git \
    wget \
    curl \
    bash \
    libgl1 \
    software-properties-common \
    openssh-server \
    nginx \
    ca-certificates

# Clean up
RUN apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/conda && \
    rm Miniconda3-latest-Linux-x86_64.sh

# Create cell2fate environment with CUDA support
RUN conda create -y -n cell2fate_env python=3.9 && \
    conda clean -afy

# Install CUDA-enabled PyTorch and cell2fate dependencies
RUN source /opt/conda/bin/activate cell2fate_env && \
    conda install -y pytorch cudatoolkit=11.8 -c pytorch -c nvidia && \
    pip install --no-cache-dir git+https://github.com/BayraktarLab/cell2fate && \
    pip install --no-cache-dir \
    ipykernel \
    notebook==6.5.5 \
    jupyterlab \
    ipywidgets \
    jupyter-archive \
    jupyter_contrib_nbextensions && \
    python -m ipykernel install --user --name=cell2fate_env --display-name='Environment (cell2fate_env)' && \
    jupyter contrib nbextension install --user && \
    jupyter nbextension enable --py widgetsnbextension

# Remove existing SSH host keys
RUN rm -f /etc/ssh/ssh_host_*

# NGINX Proxy
COPY container-template/proxy/nginx.conf /etc/nginx/nginx.conf
COPY container-template/proxy/readme.html /usr/share/nginx/html/readme.html

# Start script
COPY start.sh /
RUN chmod +x /start.sh

# Configure conda init for bash
RUN conda init bash 

# Set default command
CMD ["/start.sh"]