PROJECT ?= object-detection
MOUNT_WORKSPACE_TO ?= /home/

DOCKER_BASE_TAG ?= 10.1-cudnn7-devel-ubuntu18.04
DOCKER_BASE_IMG ?= nvidia/cuda:${DOCKER_BASE_TAG}  #https://gitlab.com/nvidia/container-images/cuda/blob/master/doc/supported-tags.md

TF_PACKAGE ?= tensorflow-gpu
TF_PACKAGE_VERSION ?= 1.13.2  #  1.12.3, 1.13.2, 1.14.0, 1.15.3, 2.0.2, 2.1.0, 2.1.1, 2.2.0
TF_MODEL_BRANCH ?= r1.13.0  # https://github.com/tensorflow/models/tags

TORCH_VERSION ?= 1.5.0+cu101	#1.3.1+cu100, 1.4.0+cu100, 1.5.0+cu101
TORCHVISION_VERSION ?= 0.6.0+cu101 	#0.4.2+cu100, 0.5.0+cu100, 0.6.0+cu101

DOCKER_TAG_TF = $(strip ${TF_PACKAGE}-${TF_PACKAGE_VERSION})
DOCKER_TAG_PT = $(strip pytorch-$(shell echo ${TORCH_VERSION} | cut -c1-5))
DOCKER_TAG_CU = $(strip cuda-$(shell echo ${DOCKER_BASE_TAG} | cut -c1-4))
DOCKER_IMAGE ?= ${PROJECT}:${DOCKER_TAG_TF}-${DOCKER_TAG_PT}-${DOCKER_TAG_CU}

CURRENT_UID := $(shell id -u)
CURRENT_GID := $(shell id -g)
DATA ?= ${PWD}/data
SHMSIZE ?= 32G

DOCKER_OPTS := \
	--name ${PROJECT} \
	--rm -it \
	--gpus all \
	--shm-size=${SHMSIZE} \
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
	-e CUDA_DEVICE_ORDER="PCI_BUS_ID" \
	--privileged \
	--ipc=host \
	--network=host

.PHONY: all clean docker-build 

all: clean

clean:
	find . -name "*.pyc" | xargs rm -f && \
	find . -name "__pycache__" | xargs rm -rf

docker-build:
	docker build \
		--build-arg FROM_IMAGE_NAME=${DOCKER_BASE_IMG} \
		--build-arg TF_PACKAGE=${TF_PACKAGE} \
		--build-arg TF_PACKAGE_VERSION=${TF_PACKAGE_VERSION} \
		--build-arg TF_MODEL_BRANCH=${TF_MODEL_BRANCH} \
		--build-arg TORCH_VERSION=${TORCH_VERSION} \
		--build-arg TORCHVISION_VERSION=${TORCHVISION_VERSION} \
		-t ${DOCKER_IMAGE} .

docker-run-bash: docker-build
	docker run ${DOCKER_OPTS} ${DOCKER_IMAGE} bash

docker-run-jupyter: docker-build
	docker run ${DOCKER_OPTS} ${DOCKER_IMAGE} \
		bash -c "jupyter lab --port=8888 --ip=0.0.0.0 --allow-root \
		--NotebookApp.token='' --notebook-dir=${MOUNT_WORKSPACE_TO} --no-browser"

docker-run-default: docker-build
	docker run ${DOCKER_OPTS} ${DOCKER_IMAGE}

docker-run-cmd: docker-build
	docker run ${DOCKER_OPTS} ${DOCKER_IMAGE} \
		bash -c "${CMD}"

docker-exec-bash:
	docker exec -it ${PROJECT} bash
