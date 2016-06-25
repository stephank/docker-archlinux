#!/bin/bash
# Usage: ./all.sh <repo>
# Builds all image variants.
set -xe
cd "$(dirname "$0")"

# Architectures to build.
archs=${archs-x86_64 i686 arm armv6 armv7 aarch64}
# Variants to build.
variants="latest base devel makepkg"

# Parse arguments.
[ $# -eq 1 ]
repo=$1

# Clear previous build products.
./support/clean-repo.sh ${repo}

# Perform builds.
for arch in ${archs}; do
    ./build.sh ${repo} ${arch}
done
# Aliases.
for variant in ${variants}; do
    docker tag ${repo}:x86_64-${variant} ${repo}:${variant}
done

# Push images.
for arch in ${archs}; do
    for variant in ${variants}; do
        docker push ${repo}:${arch}-${variant}
    done
done
# Aliases.
for variant in ${variants}; do
    docker push ${repo}:${variant}
done
