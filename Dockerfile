# 基础镜像
FROM ubuntu:23.10

# 设置环境变量（示范用，方便后续扩展）
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH=/opt/conda/bin:/usr/local/bin:$PATH

# 安装系统依赖（编译工具、wget、curl、Python3、R等）
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    wget \
    curl \
    python3 \
    python3-pip \
    bzip2 \
    ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 安装 Miniconda（用于安装 LAST）
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p /opt/conda && \
    rm /tmp/miniconda.sh && \
    /opt/conda/bin/conda clean -afy

# 安装 LAST（包含 maf-swap、maf-sort）
RUN /opt/conda/bin/conda install -c bioconda last -y && /opt/conda/bin/conda clean -afy

# 下载并安装 LASTZ
RUN wget https://github.com/lastz/lastz/archive/refs/tags/1.04.03.tar.gz -O /tmp/lastz.tar.gz && \
    tar -xzf /tmp/lastz.tar.gz -C /tmp && \
    cd /tmp/lastz-1.04.03 && make && cp src/lastz /usr/local/bin/ && \
    rm -rf /tmp/lastz*

# 下载并安装 UCSC chainNet 工具
RUN mkdir -p /opt/ucsc_tools && cd /opt/ucsc_tools && \
    wget https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/axtChain && chmod +x axtChain && \
    wget https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/chainPreNet && chmod +x chainPreNet && \
    wget https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/chainNet && chmod +x chainNet && \
    ln -s /opt/ucsc_tools/axtChain /usr/local/bin/axtChain && \
    ln -s /opt/ucsc_tools/chainPreNet /usr/local/bin/chainPreNet && \
    ln -s /opt/ucsc_tools/chainNet /usr/local/bin/chainNet

# 下载并安装 MULTIZ (TBA)
RUN wget https://www.bx.psu.edu/miller_lab/dist/multiz-tba.012109.tar.gz -O /tmp/multiz.tar.gz && \
    tar -xzf /tmp/multiz.tar.gz -C /tmp && \
    cd /tmp/multiz-tba.012109 && make && \
    cp multiz tba /usr/local/bin/ && \
    rm -rf /tmp/multiz*

# 工作目录
WORKDIR /data

# 默认命令（可根据需求修改）
CMD ["/bin/bash"]
