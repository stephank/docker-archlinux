#!/bin/bash
# Container script to build the bootstrap rootfs.
set -xe

source /bootstrap-dir/vars

# Determine URLs and filenames.
REMOTE_DIR="https://mirrors.kernel.org/archlinux/iso/${BOOTSTRAP_VERSION}"
TAR_FILENAME="archlinux-bootstrap-${BOOTSTRAP_VERSION}-x86_64.tar.gz"
SIG_FILENAME="${TAR_FILENAME}.sig"

# Grab signatures now. (Fail early)
curl -SLO "${REMOTE_DIR}/sha1sums.txt"
curl -SLO "${REMOTE_DIR}/${SIG_FILENAME}"

# Get the signing key.
gpg --keyserver "${GPG_KEYSERVER}" --recv-keys "${BOOTSTRAP_SIGNING_KEY}"

# Download the bootstrap tarball.
curl -SLO "${REMOTE_DIR}/${TAR_FILENAME}"

# Grab a copy of QEMU static binaries.
apt-get update -y
apt-get install -y qemu-user-static

# Verify the downloaded file.
grep " ${TAR_FILENAME}\$" sha1sums.txt | sha1sum -c -
gpg --verify "${SIG_FILENAME}"

# Unpack the rootfs.
tar -xpzf "${TAR_FILENAME}"

# Add QEMU to the rootfs.
cp /usr/bin/qemu-*-static root.x86_64/usr/bin

# Repack the rootfs, stripping the first component.
tar -C root.x86_64 -czf /bootstrap-dir/_rootfs.tar.gz .
