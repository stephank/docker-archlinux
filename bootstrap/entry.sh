#!/bin/bash
# Entrypoint of the bootstrap image.
set -xe

# Get target config variables.
source /target-dir/vars

# Create filesystem structure.
mkdir -m 0755 -p /build/var/{cache/pacman/pkg,lib/pacman,log} /build/{dev,run,etc}
mkdir -m 1777 -p /build/tmp
mkdir -m 0555 -p /build/{sys,proc}

# Copy any QEMU binaries over.
if compgen -G "/target-dir/qemu-*-static" > /dev/null; then
    mkdir -p /build/usr/bin
    cp -aL /target-dir/qemu-*-static /build/usr/bin
fi

# Overwrite pacman config.
rm -r /etc/pacman*
cp -a /target-dir/pacman* /etc

# Get the keyring.
curl -SL "${KEYRING_URL}" -o /tmp/pacman-keyring.tar.xz
curl -SL "${KEYRING_URL}.sig" -o /tmp/pacman-keyring.tar.xz.sig
gpg --keyserver "${GPG_KEYSERVER}" --recv-keys "${KEYRING_SIGNING_KEY}"
gpg --verify /tmp/pacman-keyring.tar.xz.sig
tar -C / -xpJf /tmp/pacman-keyring.tar.xz usr/share/pacman/keyrings/

# Initialize the keyring.
pacman-key --init
pacman-key --populate "${KEYRING_NAME}"

# Install the base group.
pacman --noconfirm -r /build \
    --logfile /tmp/pacman.log \
    --cachedir=/tmp/pacman-cache \
    -Sy coreutils bash pacman

# Copy pacman config.
rm -r /build/etc/pacman*
cp -a /etc/pacman* /build/etc

# Remove the sync database.
rm -r /build/var/lib/pacman/sync

# Create the tarball.
tar -C /build -czf /target-dir/_rootfs.tar.gz .
