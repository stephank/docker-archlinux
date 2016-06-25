#!/bin/bash
# Clean caches used in the build.
# Usage: clean.sh
set -xe
cd "$(dirname "$0")"

# Parse arguments.
[ $# -eq 0 ]

# Clean bootstrap images.
./support/clean-repo.sh archlinux-bootstrap

# Clean package caches.
rm -r ./target-*/_cache || true
