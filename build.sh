#!/bin/bash
# Create an image using a pacstrap-like process.
# Usage: pacstrap.sh <tag> <packages...>
set -xe
cd "$( dirname "${BASH_SOURCE[0]}" )"

# Args check.
[ $# -ge 1 ]

# Extra settings.
ARCH="${ARCH-x86_64}"

# Other scripts depend on these as well.
export ARCH

# Build the pacstrap image.
"./pacstrap-${ARCH}/build.sh"

# Create a temporary build directory.
# This is cheesy, but `mktemp -d` does not always result in a directory that is
# shared with the docker host (e.g. Docker for Mac), and additional options are
# not portable across implementations.
BUILD_DIR="$(mktemp _build-XXXXXX)"
rm "${BUILD_DIR}"
cp -a skel "${BUILD_DIR}"
trap "rm -r '${BUILD_DIR}'" exit

# Build a rootfs tarball inside a pacstrap container.
docker run --rm \
    -v "${PWD}/_cache-${ARCH}:/cache" \
    -v "${PWD}/${BUILD_DIR}:/out" \
    "archlinux-pacstrap:${ARCH}" ${@:2}

# Create the image from the tarball.
sed -e "s|%ARCH%|${ARCH}|g" \
    < "${BUILD_DIR}/Dockerfile.in" \
    > "${BUILD_DIR}/Dockerfile"
docker build -t "$1" "${BUILD_DIR}"
