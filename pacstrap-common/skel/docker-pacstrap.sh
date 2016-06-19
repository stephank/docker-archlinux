#!/bin/bash
# Entrypoint of the pacstrap image.
set -xe

# Create filesystem structure.
mkdir -m 0755 -p /build/var/{cache/pacman/pkg,lib/pacman,log} /build/{dev,run,etc}
mkdir -m 1777 -p /build/tmp
mkdir -m 0555 -p /build/{sys,proc}

# Copy the sync databases.
cp -a /var/lib/pacman/sync /build/var/lib/pacman

# Copy any QEMU binaries over.
if compgen -G "/usr/bin/qemu-*-static" > /dev/null; then
    mkdir -p /build/usr/bin
    cp -a /usr/bin/qemu-*-static /build/usr/bin
fi

# Sometimes, the DNS resolver mysteriously times out on the first query.
# Gently poke mirrors here so pacman won't fail.
perl -ne 'gethostbyname($1) if /^Server = https?:\/\/(.+)\//' < /etc/pacman.d/mirrorlist \

# Run pacman.
pacman --noconfirm -r /build \
    --logfile /var/log/docker-pacstrap.log \
    --cachedir=/cache \
    -S $@

# Architecture prep.
/prep-pacman.sh /build

# Copy the keyring.
cp -a /etc/pacman.d/gnupg /build/etc/pacman.d/

# Copy the mirrorlist.
cp -a /etc/pacman.d/mirrorlist /build/etc/pacman.d/

# Remove the sync databases.
rm /build/var/lib/pacman/sync/*

# Create the tarball.
tar -C /build -czf /out/rootfs.tar.gz .
