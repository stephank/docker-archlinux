#!/bin/bash
# Bootstrap container script to build the image rootfs.
set -xe

# Get target config variables.
source /target-dir/vars

# Clean the output directory.
rm -fr /target-dir/_image

# Get the keyring.
curl -SL "${keyring_url}" -o /tmp/pacman-keyring.tar.xz
curl -SL "${keyring_url}.sig" -o /tmp/pacman-keyring.tar.xz.sig
gpg --keyserver "${gpg_keyserver}" --recv-keys "${keyring_signing_key}"
gpg --verify /tmp/pacman-keyring.tar.xz.sig
tar -C / -xpJf /tmp/pacman-keyring.tar.xz usr/share/pacman/keyrings/

# Overwrite our own pacman config.
rm -r /etc/pacman*
cp -a /target-dir/pacman* /etc

# Initialize the keyring.
pacman-key --init
pacman-key --populate "${keyring_name}"

# Mount the first layer.
layer=1
mkdir -p /build/root /build/L1
mount -t aufs -o dio,xino=/dev/shm/aufs.xino,dirperm1,br:/build/L1=rw+wh none /build/root
cleanup() {
    umount /build/root
    rm -fr /build/L* /build/root /build/sync
}
trap "cleanup" exit

# Function to tar a layer and stack a new one.
pushLayer() {
    # Parse arguments
    [ $# -eq 2 ]
    tag=$1
    comment=$2
    # Temporarily move the sync database out of the way.
    mv /build/root/var/lib/pacman/sync /build/sync
    # Set the current layer to readonly.
    mount -t aufs -o remount,mod:/build/L${layer}=ro+wh none /build/root
    # Create the tarball.
    layer_dir=/target-dir/_image/L${layer}
    mkdir -p ${layer_dir}
    tar -C /build/L${layer} --exclude '.wh..wh.*' -cf ${layer_dir}/layer.tar .
    # Write metadata to a file.
    hash="$(sha256sum ${layer_dir}/layer.tar | awk '{ print $1 }')"
    cat >> /target-dir/_image/_meta.jsonl << EOF
{ "tag": "${tag}", "comment": "${comment}", "sha256": "${hash}" }
EOF
    # Add a new layer.
    mkdir /build/L$(( ++layer ))
    # Mount the new layer read/write.
    mount -t aufs -o remount,prepend:/build/L${layer}=rw+wh none /build/root
    # Restore the sync database.
    mv /build/sync /build/root/var/lib/pacman/sync
}

# Create filesystem structure.
mkdir -m 0755 -p /build/root/var/{cache/pacman/pkg,lib/pacman,log} \
                 /build/root/{dev,run,etc}
mkdir -m 1777 -p /build/root/tmp
mkdir -m 0555 -p /build/root/{sys,proc}

# Copy any QEMU binaries over.
if compgen -G "/target-dir/qemu-*-static" > /dev/null; then
    mkdir -p /build/root/usr/bin
    cp -aL /target-dir/qemu-*-static /build/root/usr/bin
fi

# Update the package database.
build_pacman="
    pacman --noconfirm -r /build/root
        --logfile /tmp/pacman.log
        --cachedir=/target-dir/_cache
"
${build_pacman} -Sy

# Install the minimum packages.
${build_pacman} -S coreutils bash pacman
# Copy pacman config.
rm -r /build/root/etc/pacman*
cp -a /etc/pacman* /build/root/etc
# Push layer.
pushLayer latest 'pacman -S coreutils bash pacman'

# Install the base group.
${build_pacman} -S --needed base
# Push layer.
pushLayer base 'pacman -S base'

# Install the base-devel group.
${build_pacman} -S --needed base-devel
pushLayer devel 'pacman -S base-devel'

# Trim the cache directory.
${build_pacman} -Sc

# Exit trap will now do cleanup for us.
