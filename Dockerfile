# 使用 Miniconda 作为基础镜像（带 conda）
FROM continuumio/miniconda3

LABEL maintainer="louisxiong"

# 更新并安装常用工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential wget curl unzip bzip2 ca-certificates zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# 配置 conda 频道并安装 LAST
RUN conda config --add channels defaults && \
    conda config --add channels bioconda && \
    conda config --add channels conda-forge && \
    conda install -y last && \
    conda clean -afy

# 安装 LASTZ 1.04.03
WORKDIR /opt
RUN wget https://github.com/lastz/lastz/archive/refs/tags/1.04.03.tar.gz && \
    tar -xzf 1.04.03.tar.gz && \
    cd lastz-1.04.03 && make && cp lastz /usr/local/bin && \
    cd .. && rm -rf lastz-1.04.03 1.04.03.tar.gz

# 安装 UCSC 工具 axtChain, chainPreNet, chainNet
RUN wget -P /usr/local/bin https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/axtChain && \
    wget -P /usr/local/bin https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/chainPreNet && \
    wget -P /usr/local/bin https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/chainNet && \
    chmod +x /usr/local/bin/axtChain /usr/local/bin/chainPreNet /usr/local/bin/chainNet

# 安装 MULTIZ (TBA)
WORKDIR /opt
RUN wget https://www.bx.psu.edu/miller_lab/dist/multiz-tba.012109.tar.gz && \
    tar -xzf multiz-tba.012109.tar.gz && \
    cd multiz-tba.012109 && make && \
    cp tba multiz /usr/local/bin && \
    cd .. && rm -rf multiz-tba.012109 multiz-tba.012109.tar.gz

# 清理工作目录
WORKDIR /
ENV PATH="/usr/local/bin:$PATH"

# 设置默认命令
CMD ["/bin/bash"]
