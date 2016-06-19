#!/bin/bash
set -xe
ROOT="${1-/}"

# Default architecture setting is 'auto', but that doesn't
# work for i686 on a x86_64 host.
mv "${ROOT}/etc/pacman.conf" "${ROOT}/etc/pacman.conf.orig"
perl -ne "s/Architecture = auto/Architecture = ${ARCH}/g; print;" \
    < "${ROOT}/etc/pacman.conf.orig" > "${ROOT}/etc/pacman.conf"
rm "${ROOT}/etc/pacman.conf.orig"
