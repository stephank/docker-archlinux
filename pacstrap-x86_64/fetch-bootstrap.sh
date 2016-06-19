#!/bin/bash
# Entrypoint of the pacstrap builder image.
set -xe

# Extra settings.
ARCH="${ARCH-x86_64}"
BOOTSTRAP_VERSION="2016.06.01"
BOOTSTRAP_GPG_KEY="4AA4767BBC9C4B1D18AE28B77F2D434B9741E8AC"
GPG_KEYSERVER="ha.pool.sks-keyservers.net"

# Determine URLs and filenames.
REMOTE_DIR="https://mirrors.kernel.org/archlinux/iso/${BOOTSTRAP_VERSION}"
TAR_FILENAME="archlinux-bootstrap-${BOOTSTRAP_VERSION}-${ARCH}.tar.gz"
SIG_FILENAME="${TAR_FILENAME}.sig"

# Download the bootstrap tarball.
curl -SLO "${REMOTE_DIR}/${TAR_FILENAME}"

# Verify the downloaded file with SHA1.
curl -SLO "${REMOTE_DIR}/sha1sums.txt"
grep " ${TAR_FILENAME}\$" sha1sums.txt | sha1sum -c -

# Verify the downloaded file with GPG.
curl -SLO "${REMOTE_DIR}/${SIG_FILENAME}"
gpg --keyserver "${GPG_KEYSERVER}" --recv-keys "${BOOTSTRAP_GPG_KEY}"
gpg --verify "${SIG_FILENAME}"

# Repack the tarball to strip the first component
tar -xpzf "${TAR_FILENAME}"
tar -C "root.${ARCH}" -czf "/out/rootfs-${ARCH}.tar.gz" .
