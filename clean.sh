#!/bin/bash
# Clean all bootstrap images.
# Usage: clean.sh
set -xe

# Parse arguments.
[ $# -eq 0 ]

# Clean bootstrap images.
IMAGES="$(docker images -q --format '{{.Repository}}:{{.Tag}}' archlinux-bootstrap)"
[ -z "${IMAGES}" ] || docker rmi ${IMAGES}
