# triton-dev-container

This guide provides step-by-step instructions for using a container
preconfigured with all the tools necessary to build and run Triton.
By mounting the Triton directory from your host into the development
container, you can continue working with your favorite IDE while keeping
all building and running tasks isolated within the container.

## Prerequisites

* **Docker** or **Podman**
* **NVIDIA Container Toolkit for GPU Usage**

> **_NOTE_**: If you are using an NVIDIA GPU, you also need to complete the steps
  to install the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html).


## Building the triton devcontainer

```sh
 make triton-build
```

## Running the triton devcontainer

```sh
 make triton-run triton_path=<path-to-triton-on-host>
```