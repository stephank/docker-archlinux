#!/bin/bash
# Clean build intermediates, including docker images.
# The package cache is left intact.
set -xe
cd "$( dirname "${BASH_SOURCE[0]}" )"

IMAGES="$(docker images -q archlinux-pacstrap)"
if [ ! -z "${IMAGES}" ]; then
    docker rmi ${IMAGES}
fi

rm -fr pacstrap-*/_build-*
