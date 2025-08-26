# 使用轻量级 Debian Bookworm 作为基础镜像
FROM debian:bookworm-slim

# 设置 GVM 版本参数
ARG GVM_VERSION=1.0.22

# 更新 apt 源并安装常用工具和开发依赖
RUN apt-get update && \
    apt install -y curl git mercurial make binutils bison gcc build-essential bsdmainutils && \
    # 清理 apt 缓存
    apt-get clean && \
    # 删除 apt 列表文件
    rm -rf /var/lib/apt/lists/*

# 设置 GVM 安装目录环境变量
ENV GVM_ROOT=/root/.gvm
# 设置 Go 工作空间环境变量
ENV GOPATH=/root/go
# 将 GVM 和 GOPATH 的 bin 目录加入 PATH
ENV PATH=${GVM_ROOT}/bin:${GOPATH}/bin:$PATH

# 设置容器工作目录
WORKDIR /root

# 下载并安装指定版本的 GVM (Go Version Manager)
RUN curl -sSL https://raw.githubusercontent.com/moovweb/gvm/refs/tags/${GVM_VERSION}/binscripts/gvm-installer | bash

# 创建容器启动脚本 entrypoint.sh，用于 source GVM 并执行传入命令
RUN echo '#!/bin/bash\nsource $GVM_ROOT/scripts/gvm\nexec "$@"' > /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

# 设置容器入口点为自定义启动脚本
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# 默认执行命令为显示 GVM 版本
CMD ["gvm", "version"]
