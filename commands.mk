
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
