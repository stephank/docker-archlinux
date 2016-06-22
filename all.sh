#!/bin/bash
# Usage: ./all.sh <repo>
# Builds all image variants.
set -xe
cd "$(dirname "$0")"

# Architectures to build.
ARCHS=${ARCHS-x86_64 i686 arm armv6 armv7 aarch64}

# Parse arguments.
[ $# -eq 1 ]
REPO=$1

# Run a clean first.
./clean.sh

# Perform builds.
for ARCH in ${ARCHS}; do
    ./build-base.sh ${ARCH} ${REPO}:${ARCH}-latest
    ./build-devel.sh ${REPO}:${ARCH}-latest ${REPO}:${ARCH}-devel
done
# Aliases.
docker tag ${REPO}:x86_64-latest ${REPO}:latest
docker tag ${REPO}:x86_64-devel ${REPO}:devel

# Push images.
for ARCH in ${ARCHS}; do
    docker push ${REPO}:${ARCH}-latest
    docker push ${REPO}:${ARCH}-devel
done
# Aliases.
docker push ${REPO}:latest
docker push ${REPO}:devel
