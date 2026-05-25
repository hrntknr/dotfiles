#!/bin/bash
set -eu -o pipefail

# ref: https://github.com/pfnet/mncore/blob/main/sdk/0.5/mncore-sdk-minimal.Dockerfile

. /etc/os-release
MNCORE_VERSION_CODENAME="${VERSION_CODENAME}"
if [ "${MNCORE_VERSION_CODENAME}" = "resolute" ]; then
    MNCORE_VERSION_CODENAME="noble"
fi

wget https://asia-northeast1-apt.pkg.dev/doc/repo-signing-key.gpg -O /usr/share/keyrings/mncore-packages-archive-keyring.gpg.asc
chmod 644 /usr/share/keyrings/mncore-packages-archive-keyring.gpg.asc

echo "deb [signed-by=/usr/share/keyrings/mncore-packages-archive-keyring.gpg.asc] https://asia-northeast1-apt.pkg.dev/projects/mncore-packages ${MNCORE_VERSION_CODENAME} main" | tee -a /etc/apt/sources.list.d/mncore-packages.list

apt-get update -y
apt-get install -y --no-install-recommends \
    libnuma1 \
    libopenmpi3 \
    openmpi-bin \
    libjpeg8 \
    libpng16-16 \
    libjson-c5 \
    libunwind8 \
    libgomp1 \
    g++ \
    git \
    pkgconf \
    time \
    zstd \
    libtbb-dev \
    libpython3.12 \
    python3.12-dev \
    python3-pip \
    python3-wheel \
    python3-setuptools \
    python3.12-venv \
    libgpfn3-0 \
    libgpfn3-dev \
    gpfn3-smi \
    mncore-sdk=0.5 \
    && \
    apt-mark hold mncore-sdk && \
    apt-get clean
