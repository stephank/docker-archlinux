#!/bin/bash
# Create a devel image from a base image.
# Usage: build-devel.sh <base tag> <devel tag>
set -xe
cd "$(dirname "$0")"

# Parse arguments.
[ $# -eq 2 ]
BASE_TAG=$1
DEVEL_TAG=$2

# Create temporary Dockerfile.
DOCKERFILE="$(cd devel && mktemp .Dockerfile-XXXXXX)"
trap "rm devel/${DOCKERFILE}" exit

# Render Dockerfile template.
sed -e "s|%BASE%|${BASE_TAG}|g" \
    < devel/Dockerfile.in > devel/${DOCKERFILE}

# Build image.
docker build -t ${DEVEL_TAG} -f devel/${DOCKERFILE} devel
