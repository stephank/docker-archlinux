#!/bin/bash
# Entrypoint of the pacstrap builder image.
set -xe

# Extra settings.
ARCH="${ARCH-armv7}"
BOOTSTRAP_GPG_KEY="68B3537F39A313B3E574D06777193F152BDBE6A6"
GPG_KEYSERVER="ha.pool.sks-keyservers.net"

# Determine URLs and filenames.
REMOTE_DIR="http://archlinuxarm.org/os"
TAR_FILENAME="ArchLinuxARM-${ARCH}-latest.tar.gz"
MD5_FILENAME="${TAR_FILENAME}.md5"
SIG_FILENAME="${TAR_FILENAME}.sig"

# Download the bootstrap tarball.
curl -SLO "${REMOTE_DIR}/${TAR_FILENAME}"

# Verify the downloaded file with SHA1.
curl -SLO "${REMOTE_DIR}/${MD5_FILENAME}"
md5sum -c "${MD5_FILENAME}"

# Verify the downloaded file with GPG.
curl -SLO "${REMOTE_DIR}/${SIG_FILENAME}"
gpg --keyserver "${GPG_KEYSERVER}" --recv-keys "${BOOTSTRAP_GPG_KEY}"
gpg --verify "${SIG_FILENAME}"

# Move the tarball in place.
mv "${TAR_FILENAME}" "/out/rootfs-${ARCH}.tar.gz"

# Grab a copy of qemu-arm-static from Debian.
apt-get update -y
apt-get install -y qemu-user-static
cp /usr/bin/qemu-arm-static /out
