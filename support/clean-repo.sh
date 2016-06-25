#!/bin/bash
# Untag all images in a repo.
# Usage: clean-repo.sh <repo>
set -xe

# Parse arguments.
[ $# -eq 1 ]
repo=$1

# Filter and untag.
images="$(docker images -q --format '{{.Repository}}:{{.Tag}}' ${repo})"
[ -z "${images}" ] || docker rmi ${images}
