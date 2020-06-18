# Object-detection
Dockerized workspace for 2D/3D object detection, segmentation, tracking, anything related to perception.


**Framework**: Both Tensorflow and Pytorch supported.  

**Libs**: Fastai, tensorflow models, second.pytorch and detectron2 also included  

**Data**: Most experiments would be done on public datasets like Kitti, and sometimes smaller data like Pets for quick iteration.  

**Environment variables** for easy access to different paths:
* TF_OBJECT_DETECTION_API
* SECOND_API

## Docker

### Setup
Recommended symlink your data dir to `./data`
```
ln -s <path_to_your_data_root> data
```

### Build
```
make docker-build
```
### Run

Default entry
```
make docker-run-default
```

Bash into an existing container
```
make docker-exec-bash
```

Run with bash only
```
make docker-run-bash
```

Jupyter Lab in docker
```
make docker-run-jupyter
```
### Makefile variables
You can ooveride the deafutl values of different componets of the 
docker build or run options using makefile variables from command line.
See `config.mk` for details, here are some examples:
* DATA: path to data
* TF_PACKAGE_VERSION: Tensorflow version
* TORCH_VERSION: Pytorch version

Usage: 
```
make docker-build TF_PACKAGE_VERSION=2.0.0
```

