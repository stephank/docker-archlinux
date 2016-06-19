#!/bin/bash
# Create the pacstrap image.
set -xe
cd "$( dirname "${BASH_SOURCE[0]}" )"

# Extra settings.
ARCH="${ARCH-armv7}"

if [ ! -d "_build-${ARCH}" ]; then
    # Copy the build directory from the skeleton.
    cp -aL skel "_build-${ARCH}"
    # Fetch the bootstrap in the build directory.
    docker run --rm -e "ARCH=${ARCH}" \
        -v "${PWD}/_build-${ARCH}:/out" \
        -i buildpack-deps:sid < ./fetch-bootstrap.sh
fi

# Build the pacstrap image.
sed -e "s|%ARCH%|${ARCH}|g" \
    < "_build-${ARCH}/Dockerfile.in" \
    > "_build-${ARCH}/Dockerfile"
docker build -t "archlinux-pacstrap:${ARCH}" "_build-${ARCH}"
