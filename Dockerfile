FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

# Set environment variables to non-interactive (this prevents some prompts)
ENV DEBIAN_FRONTEND=noninteractive

# Update and install some essential packages
RUN apt-get update && apt-get install -y \
    software-properties-common \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# install requirements for trimip -r requirements.txt
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libavformat-dev \
    libavcodec-dev \
    libavdevice-dev \
    libavutil-dev \
    libavutil-dev \
    libavfilter-dev \
    libswscale-dev \
    libswresample-dev

# Install Python 3 (Ubuntu 22.04 comes with Python 3.10)
RUN apt-get update && apt-get install -y python3 python3-pip

# Set the working directory inside the container
# WORKDIR /usr/src/app
WORKDIR /app

##############################
# Install PyTorch / TinyCuda #
##############################

RUN pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
RUN TCNN_CUDA_ARCHITECTURES=89 pip install git+https://github.com/NVlabs/tiny-cuda-nn/#subdirectory=bindings/torch

######################
# Install nvdiffrast #
######################

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    pkg-config \
    libglvnd0 \
    libgl1 \
    libglx0 \
    libegl1 \
    libgles2 \
    libglvnd-dev \
    libgl1-mesa-dev \
    libegl1-mesa-dev \
    libgles2-mesa-dev \
    cmake 

RUN git clone --branch v0.3.1 https://github.com/NVlabs/nvdiffrast.git --single-branch

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# for GLEW
ENV LD_LIBRARY_PATH /usr/lib64:$LD_LIBRARY_PATH

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility,graphics

# Default pyopengl to EGL for good headless rendering support
ENV PYOPENGL_PLATFORM egl

RUN cp nvdiffrast/docker/10_nvidia.json /usr/share/glvnd/egl_vendor.d/10_nvidia.json

RUN pip3 install --upgrade pip
RUN pip3 install ninja imageio imageio-ffmpeg

RUN mkdir -p /tmp/pip/nvdiffrast
RUN cp -r nvdiffrast/nvdiffrast /tmp/pip/nvdiffrast/
RUN cp nvdiffrast/setup.py /tmp/pip/
RUN cd /tmp/pip && pip install .

# Install pip requirements from TriMipRF
COPY requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt