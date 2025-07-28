FROM continuumio/miniconda3

LABEL maintainer="louisxiong"

# 更新并安装 R + 常用工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential wget curl unzip bzip2 ca-certificates r-base python3 python3-pip samtools \
    && rm -rf /var/lib/apt/lists/*

# 配置 conda 频道并安装工具
RUN conda config --add channels defaults && \
    conda config --add channels bioconda && \
    conda config --add channels conda-forge && \
    conda install -y last lastz && \
    conda clean -afy

# 安装 UCSC 工具 axtChain, chainPreNet, chainNet
RUN wget -P /usr/local/bin https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/axtChain && \
    wget -P /usr/local/bin https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/chainPreNet && \
    wget -P /usr/local/bin https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/chainNet && \
    wget -P /usr/local/bin https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/netToAxt && \
    wget -P /usr/local/bin https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/axtToMaf && \
    wget -P /usr/local/bin https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/mafToAxt && \
    wget -P /usr/local/bin https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/faToTwoBit && \
    chmod +x /usr/local/bin/axtChain /usr/local/bin/chainPreNet /usr/local/bin/chainNet

# 安装 MULTIZ (TBA)
WORKDIR /opt
RUN wget -P /usr/local/bin http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/multiz/tba && \
    wget -P /usr/local/bin http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/multiz/multiz && \
    chmod +x /usr/local/bin/tba /usr/local/bin/multiz

# 清理
WORKDIR /
ENV PATH="/usr/local/bin:$PATH"
CMD ["/bin/bash"]
