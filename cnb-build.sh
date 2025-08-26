#!/bin/bash

# 引入入口脚本（通常包含公共函数或环境变量）
source /usr/local/bin/entrypoint.sh


# ------------------------------
# 信息输出函数
# ------------------------------

# 打印普通信息
info() {
    local msg="$1"
    echo -e "\033[32m[INFO] $msg\033[0m"
}

# 打印成功信息
success() {
    local msg="$1"
    echo -e "\033[32m[✔ SUCCESS] $msg\033[0m"
}

# 打印错误信息并输出到 stderr
error() {
    local msg="$1"
    echo -e "\033[31m[ERROR] $msg\033[0m" >&2
}

# ------------------------------
# 通用步骤函数
# ------------------------------

# 执行一个步骤，并打印步骤标题和结果
step() {
    local msg="$1"
    shift
    echo -e "\n\033[1;33m==> $msg\033[0m"  # 黄色高亮步骤标题
    if "$@"; then
        success "$msg completed."
    else
        error "$msg failed!"
        exit 1
    fi
}

# ------------------------------
# 配置变量
# ------------------------------

# Go 版本，默认 go1.23.12，可通过 PLUGIN_GO_VERSION 覆盖
GO_VERSION="${PLUGIN_GO_VERSION:-"go1.23.12"}"

# 构建临时目录，默认 dist，可通过 PLUGIN_TEMP_PATH 覆盖
TEMP_PATH="${PLUGIN_TEMP_PATH:-dist}"

# Go 主入口文件，默认 main.go，可通过 PLUGIN_MAIN_GO 覆盖
MAIN_GO="${PLUGIN_MAIN_GO:-"main.go"}"

# 构建版本号，默认 main，可通过 PLUGIN_VERSION 覆盖
BUILD_VERSION="${PLUGIN_VERSION:-"main"}"

# 二进制文件名称，默认 main，可通过 PLUGIN_BINNAME 覆盖
BUILD_BINNAME="${PLUGIN_BINNAME:-"main"}"

# 构建环境变量，默认 CGO_ENABLED=0，可通过 PLUGIN_BUILD_ENVS 覆盖
BUILD_ENVS="${PLUGIN_BUILD_ENVS:-"CGO_ENABLED=0"}"

# Go 构建参数，默认 "-ldflags '-s -w -X main.version=${BUILD_VERSION}'"
BUILD_FLAGS="${PLUGIN_BUILD_FLAGS:-"-ldflags '-s -w -X main.version=${BUILD_VERSION}'"}"

# 构建平台列表，默认多平台，可通过 PLUGIN_ARCHS 覆盖
BUILD_ARCHS="${PLUGIN_ARCHS:-"windows/amd64 windows/arm64 linux/amd64 linux/arm64 darwin/amd64 darwin/arm64"}"

# 打包附加文件，例如 README.md、LICENSE，可通过 PLUGIN_PACK_FILES 覆盖
PACK_FILES="${PLUGIN_PACK_FILES:-}"

# ------------------------------
# 检查 GVM 支持的 Go 版本
# ------------------------------

AVAILABLE=$(gvm listall | awk '{print $1}')  # 获取所有版本列表
if echo "$AVAILABLE" | grep -Fxq "$GO_VERSION"; then
    info "Go version '$GO_VERSION' is available in GVM."
else
    error "Go version '$GO_VERSION' is NOT available in GVM."
    error "Available versions are: $AVAILABLE"
    exit 1
fi

# 安装指定 Go 版本（二进制安装）
step "Installing Go ${GO_VERSION} from binary source" gvm install "${GO_VERSION}" -B

# 设置为默认 Go 版本
step "Setting Go ${GO_VERSION} as default" gvm use "${GO_VERSION}" --default

info "run $(go version)"
# ------------------------------
# 构建函数
# ------------------------------

build() {
    local GOOS=$1            # 构建目标系统
    local GOARCH=$2          # 构建目标架构
    local BUILD_TMP_PATH="${TEMP_PATH}/${BUILD_BINNAME}_${GOOS}_${GOARCH}"  # 临时构建目录

    # 清理旧目录并创建新目录
    rm -rf "${BUILD_TMP_PATH}" && mkdir -p "${BUILD_TMP_PATH}"
    info "Created build temp path: ${BUILD_TMP_PATH}"

    # 确定输出二进制名称
    local out_bin_name="${BUILD_BINNAME}"
    [ "$GOOS" == "windows" ] && out_bin_name="${BUILD_BINNAME}.exe"

    # 构建 Go 二进制文件
    step "Building ${BUILD_BINNAME} for ${GOOS}/${GOARCH}, version: ${BUILD_VERSION}" bash -c "
        GOOS=${GOOS} GOARCH=${GOARCH} ${BUILD_ENVS} go build ${BUILD_FLAGS} -o '${BUILD_TMP_PATH}/${out_bin_name}' '${MAIN_GO}'
    "

    # 添加附加文件
    if [ -n "${PACK_FILES}" ]; then
        step "Adding extra files to build"
        shopt -s nullglob  # 支持通配符，忽略不存在文件
        for f in ${PACK_FILES}; do
            if [ -e "$f" ]; then
                cp -r "$f" "${BUILD_TMP_PATH}/"
                info "Added: $f"
            else
                info "Skipped (not found): $f"
            fi
        done
        shopt -u nullglob
    fi

    # 打包构建产物
    local pack_name="${BUILD_BINNAME}_${GOOS}_${GOARCH}"
    local pack_filename
    if [ "$GOOS" == "windows" ]; then
        pack_filename="${pack_name}.zip"
        step "Packing into ${pack_filename}" bash -c "(cd '${BUILD_TMP_PATH}' && zip -r -q '../${pack_filename}' .)"
    else
        pack_filename="${pack_name}.tar.gz"
        step "Packing into ${pack_filename}" bash -c "(cd '${BUILD_TMP_PATH}' && tar -czf '../${pack_filename}' .)"
    fi

    success "Build and packaging completed: ${pack_filename}"
}

# ------------------------------
# 顺序构建每个平台
# ------------------------------
for arch in ${BUILD_ARCHS}; do
    GOOS="${arch%/*}"      # 提取系统
    GOARCH="${arch#*/}"    # 提取架构
    build "$GOOS" "$GOARCH"  # 调用构建函数
done

# ------------------------------
# 生成统一校验文件
# ------------------------------
# 启用 nullglob，避免通配符匹配不到文件时报错
shopt -s nullglob

# 获取所有打包文件
files=("${TEMP_PATH}"/*.{zip,tar.gz})
# 判断是否有文件
if [ ${#files[@]} -eq 0 ]; then
    info "No build artifacts found in ${TEMP_PATH}, skipping checksum generation."
else
    sha256sum "${files[@]}" > "${TEMP_PATH}/${BUILD_BINNAME}_${BUILD_VERSION}_checksums.sha256"
    md5sum    "${files[@]}" > "${TEMP_PATH}/${BUILD_BINNAME}_${BUILD_VERSION}_checksums.md5"
    success "Checksums generated for files: ${files[*]}"
fi
# 关闭 nullglob
shopt -u nullglob


