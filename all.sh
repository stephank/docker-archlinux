#!/bin/sh
# Usage: ./all.sh <repo>
# Builds all image variants.
set -xe
cd "$( dirname "${BASH_SOURCE[0]}" )"

# Args check.
[ $# -eq 1 ]

# Architectures to build.
ARCHS=${ARCHS-x86_64 i686 armv7}

# Perform builds.
for ARCH in ${ARCHS}; do
    export ARCH
    ./build.sh $1:${ARCH}-latest base
    ./build.sh $1:${ARCH}-devel base base-devel
done
# Aliases.
docker tag $1:x86_64-latest $1:latest
docker tag $1:x86_64-devel $1:devel

# Push images.
for ARCH in ${ARCHS}; do
    docker push $1:${ARCH}-latest
    docker push $1:${ARCH}-devel
done
# Aliases.
docker push $1:latest
docker push $1:devel
