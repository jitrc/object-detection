
ARG FROM_IMAGE_NAME=nvidia/cuda:10.1-cudnn7-devel
FROM ${FROM_IMAGE_NAME}

# ------------------- Set TERM to suppress warning messages -------------------
ARG DEBIAN_FRONTEND=noninteractive
ARG TERM=xterm
ARG LANG=en_US.UTF-8
ARG LC_ALL=C.UTF-8


# ==================================================================
# Common tools
# ------------------------------------------------------------------
RUN apt-get update && apt-get install -y \
  bash-completion \
  build-essential \
  byobu \
  curl \
  dtrx \
  git \
  htop \
  iputils-ping \
  nano \
  software-properties-common \
  sudo \
  tmux \
  tree \
  unzip \
  vim \
  wget  \
  && rm -rf /var/lib/apt/lists/* 
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# --------------
# Nvidia opengl
# --------------

RUN dpkg --add-architecture i386 && \
  apt-get update && apt-get install -y --no-install-recommends \
  libglvnd0 libglvnd0:i386 \
  libgl1 libgl1:i386 \
  libglx0 libglx0:i386 \
  libegl1 libegl1:i386 \
  libgles2 libgles2:i386 \
  && rm -rf /var/lib/apt/lists/*

RUN printf '{\n    "file_format_version" : "1.0.0",\n\
    "ICD" : {\n        "library_path" : "libEGL_nvidia.so.0"\n    }\n}' \
    >> /usr/share/glvnd/egl_vendor.d/10_nvidia.json

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES \
        ${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES \
        ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics,compat32,utility

# --------------
# GUI tools
# --------------
RUN apt-get update && apt-get install -y \
  dbus-x11 \
  mesa-utils \
  terminator  \
  x11-apps \
  && rm -rf /var/lib/apt/lists/* 

# Some QT-Apps
ENV QT_X11_NO_MITSHM=1


# ==================================================================
# Common Python tools/libs
# ------------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip &&\
    ln -s $(which python3) /usr/local/bin/python

RUN python3 -m pip --no-cache-dir install --upgrade \
    pip \
    setuptools

RUN python3 -m pip install --no-cache-dir Cython

RUN python3 -m pip install --no-cache-dir \
  absl-py \
  sklearn \
  scipy \
  scikit-image \
  pillow \
  pandas \
  opencv-python \
  numpy \
  matplotlib \
  jupyterlab \
  ipywidgets


# ==================================================================
# Dependencies
# ------------------------------------------------------------------
WORKDIR /tmp

# --------------
# protoc 3.0.0
# --------------
# Get protoc 3.0.0, rather container may have different version
# sometimes "sudo apt-get install protobuf-compiler" will install Protobuf 3+ versions for you and some users have issues when using 3.5
RUN curl -OL "https://github.com/google/protobuf/releases/download/v3.0.0/protoc-3.0.0-linux-x86_64.zip" && \
      unzip protoc-3.0.0-linux-x86_64.zip -d proto3 && \
      mv proto3/bin/* /usr/local/bin && \
      mv proto3/include/* /usr/local/include && \
      chmod 755 /usr/local/bin/protoc && \
      rm -rf proto3 protoc-3.0.0-linux-x86_64.zip

# --------------
# CMake 3.15
# --------------
RUN apt-get purge -y  cmake \
      && cd /tmp \
      && wget --no-check-certificate https://github.com/Kitware/CMake/releases/download/v3.15.1/cmake-3.15.1-Linux-x86_64.sh \
      && chmod +x cmake-3.15.1-Linux-x86_64.sh \
      && ./cmake-3.15.1-Linux-x86_64.sh --skip-license --prefix=/usr/local \
      && rm -rf cmake-3.15.1-Linux-x86_64.sh

# --------------
# apt based
# --------------
RUN apt-get update && apt-get install -y --no-install-recommends \
      libboost-all-dev \
      libjpeg-dev \
      libpng-dev  \
      python-tk \
      && rm -rf /var/lib/apt/lists/* 

# --------------
# pip based
# --------------
RUN python3 -m pip install --no-cache-dir numba shapely fire pybind11 seaborn psutil && \
    python3 -m pip install --no-cache-dir tensorboardX contextlib2 tf_slim lxml && \
    python3 -m pip install --no-cache-dir pycocotools nuscenes-devkit

ENV NUMBAPRO_CUDA_DRIVER=/usr/lib/x86_64-linux-gnu/libcuda.so
ENV NUMBAPRO_NVVM=/usr/local/cuda/nvvm/lib64/libnvvm.so
ENV NUMBAPRO_LIBDEVICE=/usr/local/cuda/nvvm/libdevice   


# ==================================================================
# Tensorflow
# ------------------------------------------------------------------
ARG TF_PACKAGE=tensorflow
ARG TF_PACKAGE_VERSION=
RUN python3 -m pip install --no-cache-dir ${TF_PACKAGE}${TF_PACKAGE_VERSION:+==${TF_PACKAGE_VERSION}}


# ==================================================================
# Tensorflow Models
# ------------------------------------------------------------------
# Get the tensorflow models research directory, in /tensorflow to match recommendation of installation
ARG TF_MODEL_BRANCH=master
RUN mkdir -p /tensorflow && cd /tensorflow &&\
    git clone --depth 1 https://github.com/tensorflow/models.git -b ${TF_MODEL_BRANCH} 

# Run protoc on the object detection repo
RUN cd /tensorflow/models/research && \
    protoc object_detection/protos/*.proto --python_out=.

# Set the PYTHONPATH to finish installing the API
ENV PYTHONPATH $PYTHONPATH:/tensorflow/models/research:/tensorflow/models/research/slim
ENV TF_OBJECT_DETECTION_API /tensorflow/models/research/object_detection


# ==================================================================
# pytorch
# ------------------------------------------------------------------
ARG TORCH_VERSION=
ARG TORCHVISION_VERSION=
RUN python3 -m pip install --no-cache-dir \
   torch${TORCH_VERSION:+==${TORCH_VERSION}}  \
   torchvision${TORCHVISION_VERSION:+==${TORCHVISION_VERSION}} \
   -f https://download.pytorch.org/whl/torch_stable.html


# --------------
# Fastai
# --------------
RUN python3 -m pip install --no-cache-dir \
  fastai

# --------------
# apex
# --------------

RUN git clone https://github.com/NVIDIA/apex.git \
 && cd apex \
 && python setup.py install --cuda_ext --cpp_ext

WORKDIR /opt


# ==================================================================
# second.pytorch
# ------------------------------------------------------------------
ARG TORCH_CUDA_ARCH_LIST="7.0 7.5+PTX"
RUN PROBLEM_FILE=/usr/local/lib/python3.6/dist-packages/torch/share/cmake/Caffe2/Caffe2Targets.cmake && \
    sed -i 's/-Wall;-Wextra;-Wno-unused-parameter;-Wno-missing-field-initializers;-Wno-write-strings;-Wno-unknown-pragmas;-Wno-missing-braces;-fopenmp//g' $PROBLEM_FILE && \
    sed -i 's/-Wall;-Wextra;-Wno-unused-parameter;-Wno-missing-field-initializers;-Wno-write-strings;-Wno-unknown-pragmas;-Wno-missing-braces//g' $PROBLEM_FILE && \
    cd /opt && \
    git clone --depth 1 --recursive https://www.github.com/traveller59/spconv.git && \
    cd ./spconv && \
    SPCONV_FORCE_BUILD_CUDA=1 python setup.py install

RUN git clone https://github.com/traveller59/second.pytorch.git --depth 10
ENV PYTHONPATH=/opt/second.pytorch:${PYTHONPATH}
ENV SECOND_API=/opt/second.pytorch/second


# ==================================================================
# detectron2
# ------------------------------------------------------------------
RUN python3 -m pip install 'git+https://github.com/facebookresearch/fvcore'
RUN git clone https://github.com/facebookresearch/detectron2 detectron2_repo
# set FORCE_CUDA because during `docker build` cuda is not accessible
ARG FORCE_CUDA="1"
# This will by default build detectron2 for all common cuda architectures and take a lot more time,
# because inside `docker build`, there is no way to tell which architecture will be used.
# ARG TORCH_CUDA_ARCH_LIST="Kepler;Kepler+Tesla;Maxwell;Maxwell+Tegra;Pascal;Volta;Turing"
ARG TORCH_CUDA_ARCH_LIST="7.0 7.5+PTX"
ENV TORCH_CUDA_ARCH_LIST="${TORCH_CUDA_ARCH_LIST}"
RUN python3 -m pip install -e detectron2_repo

ENV CUDA_HOME=/usr/local/cuda
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64
ENV PATH=$PATH:/usr/local/cuda/bin


WORKDIR /home
EXPOSE 8888
CMD ["jupyter", "lab", "--allow-root","--NotebookApp.token=''", "--notebook-dir=/home/", "--ip=0.0.0.0", "--port=8888", "--no-browser"]
