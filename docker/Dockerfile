# Buildroot build environment (Buildroot needs a case-sensitive Linux FS).
FROM debian:bookworm-slim
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        bc bison build-essential ca-certificates cpio curl file flex git \
        libncurses-dev libssl-dev openssl python3 python3-setuptools rsync unzip \
        wget xz-utils zstd patch perl gawk \
    && rm -rf /var/lib/apt/lists/*
RUN useradd -m -u 1000 builder && mkdir -p /work && chown builder:builder /work
USER builder
WORKDIR /src
