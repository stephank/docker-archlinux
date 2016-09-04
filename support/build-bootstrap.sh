#!/bin/bash
# Container script to build the bootstrap rootfs.
set -xe

source /bootstrap-dir/vars

# Grab a copy of QEMU static binaries.
apt-get update -y
apt-get install -y gpg qemu-user-static

# Determine URLs and filenames.
remote_dir="https://mirrors.kernel.org/archlinux/iso/${bootstrap_version}"
tar_filename="archlinux-bootstrap-${bootstrap_version}-x86_64.tar.gz"
sig_filename="${tar_filename}.sig"

# Grab signatures now. (Fail early)
curl -SLO "${remote_dir}/sha1sums.txt"
curl -SLO "${remote_dir}/${sig_filename}"

# Get the signing key.
gpg --keyserver "${gpg_keyserver}" --recv-keys "${bootstrap_signing_key}"

# Download the bootstrap tarball.
curl -SLO "${remote_dir}/${tar_filename}"

# Verify the downloaded file.
grep " ${tar_filename}\$" sha1sums.txt | sha1sum -c -
gpg --verify "${sig_filename}"

# Unpack the rootfs.
tar -xpzf "${tar_filename}"

# Add QEMU to the rootfs.
cp /usr/bin/qemu-*-static root.x86_64/usr/bin

# Repack the rootfs, stripping the first component.
tar -C root.x86_64 -czf /bootstrap-dir/_rootfs.tar.gz .
