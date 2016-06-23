#!/bin/bash
# Create images for a specific archicture.
# Usage: build.sh <repo> <architecture>
set -xe
cd "$(dirname "$0")"

# Parse arguments.
[ $# -eq 2 ]
REPO=$1
ARCH=$2

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
docker build -t ${REPO}:${ARCH}-latest target-${ARCH}

# Cleanup the rootfs tarball.
rm target-${ARCH}/_rootfs.tar.gz

# Function to build derivatives.
derive() {
    VARIANT=$1
    BASE=$2

    # Create temporary Dockerfile.
    DOCKERFILE="$(cd ${VARIANT} && mktemp .Dockerfile-XXXXXX)"

    # Render Dockerfile template.
    sed -e "s|%BASE%|${REPO}:${ARCH}-${BASE}|g" \
        < ${VARIANT}/Dockerfile.in > ${VARIANT}/${DOCKERFILE}

    # Build the image.
    docker build -t ${REPO}:${ARCH}-${VARIANT} \
        -f ${VARIANT}/${DOCKERFILE} ${VARIANT}

    # Clean up temporary Dockerfile.
    rm ${VARIANT}/${DOCKERFILE}
}

# Build all derivatives.
derive base latest
derive devel base
derive makepkg devel
