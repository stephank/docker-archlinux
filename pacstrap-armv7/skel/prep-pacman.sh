#!/bin/bash
set -xe
ROOT="${1-/}"

# Default on ARM is to disable package signature checking. Re-enable it.
mv "${ROOT}/etc/pacman.conf" "${ROOT}/etc/pacman.conf.orig"
perl -ne 's/^([a-z]*siglevel = )/#\1/gi; print;' \
    < "${ROOT}/etc/pacman.conf.orig" > "${ROOT}/etc/pacman.conf"
rm "${ROOT}/etc/pacman.conf.orig"
