# docker-gvm
## Base image

This is a lightweight **Debian Bookworm slim** Docker image with **GVM (Go Version Manager)** installed.
 It provides a basic environment for managing multiple Go versions.

- **Base image**: `debian:bookworm-slim`
- **GVM version**: 1.0.22
- **Go workspace**: `/root/go`
- **Installed tools**: `curl`, `git`, `mercurial`, `make`, `binutils`, `bison`, `gcc`, `build-essential`, `bsdmainutils`

### Build the Docker Image

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

## CNB image

## Configuration

All parameters can be customized with environment variables (e.g., for CI/CD pipelines):

| Variable             | Default                                                      | Description                         |
| -------------------- | ------------------------------------------------------------ | ----------------------------------- |
| `PLUGIN_GO_VERSION`  | `go1.23.12`                                                  | Go version managed by GVM           |
| `PLUGIN_TEMP_PATH`   | `dist`                                                       | Temporary build output directory    |
| `PLUGIN_MAIN_GO`     | `main.go`                                                    | Entry Go file                       |
| `PLUGIN_VERSION`     | `main`                                                       | Build version (used in `-ldflags`)  |
| `PLUGIN_BINNAME`     | `main`                                                       | Binary output name                  |
| `PLUGIN_BUILD_ENVS`  | `CGO_ENABLED=0`                                              | Extra build environment variables   |
| `PLUGIN_BUILD_FLAGS` | `-ldflags '-s -w -X main.version=${BUILD_VERSION}'`          | Go build flags                      |
| `PLUGIN_ARCHS`       | `windows/amd64 windows/arm64 linux/amd64 linux/arm64 darwin/amd64 darwin/arm64` | Target build platforms              |
| `PLUGIN_PACK_FILES`  | *(empty)*                                                    | Extra files to include in packaging |

Run `zhiqiangwang/gvm:cnb`

```shell
docker run --rm \
  -e PLUGIN_GO_VERSION=go1.22.6 \
  -e PLUGIN_BINNAME=myapp \
  -e PLUGIN_VERSION=v1.0.0 \
  -e PLUGIN_MAIN_GO=main.go \
  -e PLUGIN_PACK_FILES="README.md LICENSE" \
  -v $(pwd):$(pwd) \
  -w $(pwd) \
  zhiqiangwang/gvm:cnb \
```
