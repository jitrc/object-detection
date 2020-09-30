PROJECT ?= object-detection
MOUNT_WORKSPACE_TO ?= /home/

DOCKER_BASE_TAG ?= 10.0-cudnn7-devel-ubuntu18.04
DOCKER_BASE_IMG ?= nvidia/cuda:${DOCKER_BASE_TAG}  #https://gitlab.com/nvidia/container-images/cuda/blob/master/doc/supported-tags.md

TF_PACKAGE ?= tensorflow-gpu
TF_PACKAGE_VERSION ?= 1.13.2  #  1.12.3, 1.13.2, 1.14.0, 1.15.3, 2.0.2, 2.1.0, 2.1.1, 2.2.0
TF_MODEL_BRANCH ?= r1.13.0  # https://github.com/tensorflow/models/tags

TORCH_VERSION ?= 1.4.0+cu100	#1.3.1+cu100, 1.4.0+cu100, 1.5.0+cu101 #https://download.pytorch.org/whl/torch_stable.html
TORCHVISION_VERSION ?= 0.5.0+cu100 	#0.4.2+cu100, 0.5.0+cu100, 0.6.0+cu101

FASTAI_VERSION ?= 1.0.61

DOCKER_TAG_TF = $(strip ${TF_PACKAGE}-${TF_PACKAGE_VERSION})
DOCKER_TAG_PT = $(strip pytorch-$(shell echo ${TORCH_VERSION} | cut -c1-5))
DOCKER_TAG_CU = $(strip cuda-$(shell echo ${DOCKER_BASE_TAG} | cut -c1-4))
DOCKER_IMAGE ?= ${PROJECT}:${DOCKER_TAG_TF}-${DOCKER_TAG_PT}-${DOCKER_TAG_CU}

CURRENT_UID := $(shell id -u)
CURRENT_GID := $(shell id -g)
DATA ?= ${PWD}/data
SHMSIZE ?= 32G
CUDA_VISIBLE_DEVICES ?= 0

DOCKER_OPTS := \
	--name ${PROJECT} \
	--rm -it \
	--gpus all \
	--shm-size=${SHMSIZE} \
	--env DISPLAY=${DISPLAY} \
	-v '/tmp/.X11-unix:/tmp/.X11-unix:rw' \
	-u ${CURRENT_UID}:${CURRENT_GID} \
	-v /etc/passwd:/etc/passwd:ro \
	-v /etc/group:/etc/group:ro \
	-v ${DATA}:/data \
	-v /media:/media \
	-v ${PWD}/workspace:${MOUNT_WORKSPACE_TO} \
	-w ${MOUNT_WORKSPACE_TO} \
	-v ${PWD}/.docker_home:/docker_home \
	-e HOME=/docker_home \
	-e TF_CPP_MIN_LOG_LEVEL=2 \
	-e TF_FORCE_GPU_ALLOW_GROWTH=true \
	-e CUDA_DEVICE_ORDER="PCI_BUS_ID" \
	-e CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES} \
	--privileged \
	--ipc=host \
	--network=host
