#!/bin/bash
# Usage: ./all.sh <repo>
# Builds all image variants.
set -xe
cd "$(dirname "$0")"

# Architectures to build.
ARCHS=${ARCHS-x86_64 i686 arm armv6 armv7 aarch64}
# Variants to build.
VARIANTS="latest base devel makepkg"

# Parse arguments.
[ $# -eq 1 ]
REPO=$1

# Run a clean first.
./clean.sh

# Perform builds.
for ARCH in ${ARCHS}; do
    ./build.sh ${REPO} ${ARCH}
done
# Aliases.
for VARIANT in ${VARIANTS}; do
    docker tag ${REPO}:x86_64-${VARIANT} ${REPO}:${VARIANT}
done

# Push images.
for ARCH in ${ARCHS}; do
    for VARIANT in ${VARIANTS}; do
        docker push ${REPO}:${ARCH}-${VARIANT}
    done
done
# Aliases.
for VARIANT in ${VARIANTS}; do
    docker push ${REPO}:${VARIANT}
done
