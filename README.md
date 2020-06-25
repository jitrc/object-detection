# Dockerized workspace for 2D/3D object detection

Anything related to Robotics and Autonomous Vehicle Perception using Deep Learning.  
May include classification, detection, segmentation, tracking, pose estimation.

**Framework**: Both Tensorflow and Pytorch supported.  

**Libs**: Fastai, tensorflow models, second.pytorch and detectron2 also included  

**Data**: Most experiments would be done on public datasets like Kitti, and sometimes smaller data like Pets for quick iteration.  

**Environment variables** for easy access to different paths:

* TF_OBJECT_DETECTION_API
* SECOND_API

## Included Notebooks/Scripts

* [Tensorflow Object Detection](workspace/tensorflow)
  * [Pets](workspace/tensorflow/Pets)
  * [Kitti](workspace/tensorflow/kitti)
* [Pytorch](workspace/pytorch)
  * [Senond/Pointpillars](workspace/pytorch/SenondPointpillars.bash_scripts.ipynb)
* [Fast.ai examples from course](workspace/fastai)

## Docker

### Setup

Recommended symlink your data dir to `./data`

```bash
$ ln -s <path_to_your_data_root> data
```

### Build

```bash
$ make docker-build
```

### Run

Here are few options, use as needed:

* Default entry `$ make docker-run-default`
* Bash into an existing container `$ make docker-exec-bash`
* Run with bash only `$ make docker-run-bash`
* Jupyter Lab in docker `$ make docker-run-jupyter`

### Makefile variables

You can override the default values of different components of the
docker build or run options using makefile variables from the command line.
See `config.mk` for details, here are some examples:

* DATA: path to data
* TF_PACKAGE_VERSION: Tensorflow version
* TORCH_VERSION: Pytorch version

Usage:

```bash
$ make docker-build TF_PACKAGE_VERSION=2.0.0
```
