# docker-archlinux

This repository contains Docker images of Arch Linux. The images aim to be as
plain and no-thrills as possible, what you'd get from `pacstrap`.

## Tags

 - `latest`: Alias for `x86_64-latest`
 - `devel`: Alias for `x86_64-devel`
 - `x86_64-latest`: Installation of `base` for `x86_64`
 - `x86_64-devel`: Installation of `base base-devel` for `x86_64`
 - `i686-latest`: Installation of `base` for `i686`
 - `i686-devel`: Installation of `base base-devel` for `i686`
 - `arm-latest`: Installation of `base` for `arm`
 - `arm-devel`: Installation of `base base-devel` for `arm`
 - `armv6-latest`: Installation of `base` for `armv6`
 - `armv6-devel`: Installation of `base base-devel` for `armv6`
 - `armv7-latest`: Installation of `base` for `armv7`
 - `armv7-devel`: Installation of `base base-devel` for `armv7`
 - `aarch64-latest`: Installation of `base` for `aarch64`
 - `aarch64-devel`: Installation of `base base-devel` for `aarch64`

The non-Intel tags contain QEMU static binaries for userland emulation on a
x86_64 host, so the images work on systems with binfmt setup in Debian-style.
(This includes Docker for Mac and Docker for Windows.)

When running the i686 images, note that the system still reports x86_64, and
scripts using autodetect may thus fail. (The default `pacman.conf` is setup
correctly.)

## Building

Currently, an `x86_64` host with binfmt setup for QEMU userland emulation.

Build the `base` image for an architecture with:

```bash
./build-base.sh <architecture> <tag>
# e.g.: ./build-base.sh x86_64 archlinux:latest
```

Build the `base base-devel` image for an architecture with:

```bash
./build-devel.sh <base tag> <devel tag>
# e.g.: ./build-devel.sh archlinux:latest archlinux:devel
```

A script is provided to clean all Docker images:

```bash
./clean.sh <repo>
# e.g.: ./build-base.sh archlinux
```

A clean, full build of all tags and push can be performed with:

```bash
./all.sh <repo>
# e.g.: ./all.sh archlinux
# Will generate: archlinux:x86_64-latest, archlinux:x86_64-devel, etc.
```

## Build process

The build process creates an intermediate image based on the Arch Linux
bootstrap tarball, but with slight modifications. This image is used to run the
actual `pacman` command and create root filesystem tarballs for the final
images.

The bootstrap images are named `archlinux-bootstrap:<version>` and its rootfs
is created by `bootstrap/buidler.sh`, which runs in an intermediate
`buildpack-deps:sid` container. The build process automatically cleans up old
bootstrap versions.

The entry point for the bootstrap image is `bootstrap/entry.sh`. This script
performs steps similar to `pacstrap`, but calls `pacman` directly.

For each architecture, we run this image and script to thus create a rootfs for
the final image with the `base` group installed. The architecture-specific
settings are in the `target-*` directories, which are shared with the container
during bootstrapping.

Once we have the final image with an install of `base`, creating images with
`base-devel` installed is simply a matter of adding a layer. Sourcefiles for
this step are in the `devel` directory.

All steps in the build process are verified with GnuPG. (This includes the ARM
builds, which have signature verification enabled, unlike regular Arch Linux
ARM installs.)

## To-do

 - Add support for builds on non-x86_64 hosts. (ARM native builds.)
 - Prevent republish when there are no package changes.
