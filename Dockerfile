# Start with CUDA 11.3 base image
FROM nvidia/cuda:11.3.1-cudnn8-devel-ubuntu20.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV SHELL=/bin/bash
ENV PATH=/opt/conda/bin:$PATH

# Set the working directory
WORKDIR /

# Create workspace directory
RUN mkdir /workspace

# Install system dependencies
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get update --fix-missing && \
    apt-get install -y locales && \
    locale-gen en_US.UTF-8 && \
    apt-get install --yes --no-install-recommends \
    git \
    wget \
    curl \
    bash \
    libgl1 \
    software-properties-common \
    openssh-server \
    nginx \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /miniconda.sh && \
    bash /miniconda.sh -b -p /opt/conda && \
    rm /miniconda.sh

# Create cell2fate environment
RUN conda create -y -n cell2fate_env python=3.9 && \
    conda run -n cell2fate_env pip install torch==1.11.0+cu113 -f https://download.pytorch.org/whl/torch_stable.html && \
    conda run -n cell2fate_env pip install git+https://github.com/BayraktarLab/cell2fate && \
    conda run -n cell2fate_env pip install ipykernel jupyter "notebook<7" jupyterlab jupyter_contrib_nbextensions && \
    conda run -n cell2fate_env python -m ipykernel install --user --name=cell2fate_env --display-name='Environment (cell2fate_env)'

# Set up Jupyter extensions
RUN conda run -n cell2fate_env jupyter contrib nbextension install --user && \
    conda run -n cell2fate_env jupyter nbextension enable --py widgetsnbextension

# Remove existing SSH host keys
RUN rm -f /etc/ssh/ssh_host_*

# Configure NGINX for proxy
COPY container-template/proxy/nginx.conf /etc/nginx/nginx.conf
COPY container-template/proxy/readme.html /usr/share/nginx/html/readme.html

# Copy start script
COPY container-template/start.sh /
RUN chmod +x /start.sh

# Add conda init to bashrc
RUN echo '. /opt/conda/etc/profile.d/conda.sh' >> ~/.bashrc

# Welcome message
COPY container-template/runpod.txt /etc/runpod.txt
RUN echo 'cat /etc/runpod.txt' >> ~/.bashrc
RUN echo 'echo -e "\nFor detailed documentation and guides, please visit:\n\033[1;34mhttps://docs.runpod.io/\033[0m\n\n"' >> ~/.bashrc

# Set the default command
CMD ["/start.sh"]