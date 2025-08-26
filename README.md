# docker-gvm
## Image Overview

This is a lightweight **Debian Bookworm slim** Docker image with **GVM (Go Version Manager)** installed.
 It provides a basic environment for managing multiple Go versions.

- **Base image**: `debian:bookworm-slim`
- **GVM version**: 1.0.22
- **Go workspace**: `/root/go`
- **Installed tools**: `curl`, `git`, `mercurial`, `make`, `binutils`, `bison`, `gcc`, `build-essential`, `bsdmainutils`

## Quick Start

## Build the Docker Image

```
docker build -t zhiqiangwang/gvm:latest .
```

### View GVM Version (Default Command)

~~~
docker run --rm -it zhiqiangwang/gvm:latest
~~~

### Access Interactive Shell

```
docker run -it --rm zhiqiangwang/gvm:latest bash
```
