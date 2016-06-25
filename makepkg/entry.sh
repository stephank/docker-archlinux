#!/bin/bash
set -e

# Additional settings.
keyserver="${keyserver-ha.pool.sks-keyservers.net}"

# Read the PKGBUILD.
source PKGBUILD

# Fetch PGP keys used in the build.
if (( ${#validpgpkeys[@]} > 0 )); then
    echo '==> Fetching PGP keys...'
    gpg --keyserver "${keyserver}" --recv-keys ${validpgpkeys[@]}
fi

# Update the package database if we need to install dependencies.
if (( ${#depends[@]} > 0 || ${#makedepends[@]} > 0 )); then
    sudo pacman --noconfirm -Sy
fi

# Leave the rest to makepkg.
exec makepkg --noconfirm -s $@
