# docker-archlinux

This repository contains Docker images of Arch Linux. The images aim to be as
plain and no-thrills as possible, what you'd get from `pacstrap`.

## Tags

 - `latest`: Alias for `x86_64:latest`
 - `devel`: Alias for `x86_64:devel`
 - `x86_64-latest`: Installation of `base` for `x86_64`
 - `x86_64-devel`: Installation of `base base-devel` for `x86_64`
 - `i686-latest`: Installation of `base` for `i686`
 - `i686-devel`: Installation of `base base-devel` for `i686`
 - `armv7-latest`: Installation of `base` for `armv7`
 - `armv7-devel`: Installation of `base base-devel` for `armv7`

The non-Intel tags contain QEMU static binaries for userland emulation, so
should work with Docker for Mac, Docker for Windows and Debian or Ubuntu-based
systems with binfmt setup correctly.

When running the i686 images, note that the system still reports x86_64, and
scripts using autodetect may thus fail. (The default `pacman.conf` is setup
correctly.)

## Building

Individual images can be built with:

```bash
./build.sh <tag> <packages...>
# e.g.: ./build.sh archlinux:devel base base-devel
```

The default target architecture is x86_64. To build others, set ARCH:

```bash
ARCH=i686 ./build.sh archlinux:i686-devel base base-devel
```

Between builds, the bootstrap image and pacman database are cached. To build
newer versions, these should be cleaned beforehand with:

```bash
./clean.sh
```

This will not clean the package caches. These can be manually cleaned by
deleting them:

```bash
rm -fr _cache-*
```

A clean, full build of all tags and push can be performed with:

```bash
./all.sh <repo>
# Will generate: <repo>:latest, <repo>:devel, etc.
```

## Build process

The build process creates intermediate images based on stock bootstrap
tarballs. These images are used to run the actual `pacman` command and create
root filesystem tarballs for the final images.

The 'pacstrap' images are named `archlinux-pacstrap`, with tags per
architecture.  Each architecture has a `pacstrap-<arch>` subdirectory or
symlink with a `build.sh` to generate the pacstrap image.

The entry point for the pacstrap image is
`pacstrap-common/skel/docker-pacstrap.sh`. This script performs steps similar
to `pacstrap`, but calls `pacman` directly.

The pacstrap image build process performs a fetch step, which is done by
running `pacstrap-*/fetch-bootstrap.sh` in a `buildpack-deps` container,
followed by a `docker build` step. (Scripted in: `pacstrap-*/build.sh`)

The final image build process performs a pacstrap, which is done by running the
pacstrap image, followed by a `docker build` step. (Scripted in: `build.sh`)

The `docker build` steps in both cases are run in context directories that are
generated. The `skel` directories throughout the source are skeletons for these
context directories.

## To-do

 - Add support for ARMv5 and AArch64.
 - Add support for builds on non-x86_64 hosts. (ARM native builds.)
 - Add ARM keyring package GPG verification.
 - Prevent republish when there are no package changes.
