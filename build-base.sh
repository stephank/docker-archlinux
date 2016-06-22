#!/bin/bash
# Create a base image using a pacstrap-like process.
# Usage: build-base.sh <architecture> <tag>
set -xe
cd "$(dirname "$0")"

# Parse arguments.
[ $# -eq 2 ]
ARCH=$1
TAG=$2

# Get the bootstrap image settings.
source bootstrap/vars

# Create the bootstrap image if it does not exist.
if [ -z "$(docker images -q archlinux-bootstrap:${BOOTSTRAP_VERSION})" ]; then
    # Build the bootstrap rootfs.
    docker run --rm -v "${PWD}"/bootstrap:/bootstrap-dir \
        -i buildpack-deps:sid /bootstrap-dir/builder.sh

    # Remove old bootstrap images.
    ./clean.sh

    # Create the new bootstrap image.
    docker build -t archlinux-bootstrap:${BOOTSTRAP_VERSION} bootstrap

    # Cleanup the bootstrap rootfs tarball.
    rm bootstrap/_rootfs.tar.gz
fi

# Build the rootfs.
docker run --rm \
    -v "${PWD}"/target-${ARCH}:/target-dir \
    archlinux-bootstrap:${BOOTSTRAP_VERSION}

# Create the new image.
docker build -t ${TAG} target-${ARCH}

# Cleanup the rootfs tarball.
rm target-${ARCH}/_rootfs.tar.gz
