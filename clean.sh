#!/bin/bash
# Clean all docker images.
# Usage: clean.sh <repo>
set -xe

[ $# -eq 1 ]
REPO=$1

OLD_BOOTSTRAPS="$(docker images -q archlinux-bootstrap)"
[ -z "${OLD_BOOTSTRAPS}" ] || docker rmi ${OLD_BOOTSTRAPS}

OLD_IMAGES="$(docker images -q ${REPO})"
[ -z "${OLD_IMAGES}" ] || docker rmi ${OLD_IMAGES}
