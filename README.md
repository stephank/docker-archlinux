# Unofficial Arch Linux images

This repository contains unofficial Docker images of [Arch Linux] and
[Arch Linux ARM] for all available platforms.

The images aim to be as plain and no-thrills as possible, what you'd get from
`pacstrap`. This does not mean they are small, however. The `latest` image
weights in at about 100 MB, which is twice `ubuntu:latest` at the time of
writing.

However, these images can make very convenient prototype, test and build
environments in combination with Docker tooling, even on non-Linux platforms.

The images are available on Docker Hub as [stephank/archlinux]. Source for the
build process is in the GitHub repo [stephank/docker-archlinux].

 [Arch Linux]: https://www.archlinux.org/
 [Arch Linux ARM]: https://archlinuxarm.org/
 [stephank/archlinux]: https://hub.docker.com/r/stephank/archlinux/
 [stephank/docker-archlinux]: https://github.com/stephank/docker-archlinux

## Tags

Builds run daily on hardware sponsored by [Angry Bytes].

Each architecture is built in 4 variants:

 - `latest`: Installation of `coreutils`, `bash` and `pacman`.

 - `base`: Derived from `latest`, a full installation of `base`.

 - `devel`: Derived from `base`, a full installation of `base base-devel`.

 - `makepkg`: Derived from `devel`, an environment for building packages.

 [Angry Bytes]: https://angrybytes.com/

### Arch Linux tags

 - `latest`, `base`, `devel`, `makepkg` (aliases for x86_64)
 - `x86_64-latest`, `x86_64-base`, `x86_64-devel`, `x86_64-makepkg`
 - `i686-latest`, `i686-base`, `i686-devel`, `i686-makepkg`

When running the i686 images on a x86_64 host, note that the system still
reports x86_64 (e.g. in `uname -m`), and tools attempting autodetection may
thus fail. (The default `pacman.conf` is setup correctly, however.)

### Arch Linux ARM tags

 - `arm-latest`, `arm-base`, `arm-devel`, `arm-makepkg`
 - `armv6-latest`, `armv6-base`, `armv6-devel`, `armv6-makepkg`
 - `armv7-latest`, `armv7-base`, `armv7-devel`, `armv7-makepkg`
 - `aarch64-latest`, `aarch64-base`, `aarch64-devel`, `aarch64-makepkg`

The ARM images contain QEMU static binaries for userland emulation on a x86_64
host, so the images work on systems with binfmt setup in [Debian-style]. (This
includes Docker for Mac and Docker for Windows.)

The QEMU static binaries are extracted from the [qemu-user-static] package in
Debian sid.

 [Debian-style]: https://wiki.debian.org/QemuUserEmulation
 [qemu-user-static]: https://packages.debian.org/sid/qemu-user-static

## Examples

### Building packages

In a directory with a PKGBUILD file, run:

```bash
docker run --rm -v "$PWD":/build stephank/archlinux:makepkg
```

The `makepkg` images expect the build directory to be mounted as `/build`. The
actual `makepkg` tool is invoked as `makepkg --noconfirm -s`. Any additional
arguments passed to the image are added after the default arguments.

Before the build starts, PGP keys in the PKGBUILD `validpgpkeys` array are
fetched from public keyservers, and the package database is refreshed.

## Building the images

Currently, an `x86_64` host with binfmt setup for QEMU userland emulation is
required to build the images.

Build all variants of the image for a specific architecture with:

```bash
./build.sh <repo> <architecture>
# e.g.: ./build.sh archlinux x86_64
```

During the build, the Arch Linux bootstrap is cached. A script is provided to
clean these intermediate images:

```bash
./clean.sh
```

A clean, full build of all tags and push can be performed with:

```bash
./all.sh <repo>
# e.g.: ./all.sh archlinux
# Will build and push: archlinux:x86_64-latest, archlinux:x86_64-base, etc.
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

Once we have the final image with an install of `base`, creating the other
variants is simply a matter of adding layers. Sourcefiles for these steps are
in the `base`, `devel` and `makepkg` directories.

All steps in the build process are verified with GnuPG. (This includes the ARM
builds, which have signature verification enabled, unlike regular Arch Linux
ARM installs.)

## To-do

 - Add support for builds on non-x86_64 hosts. (ARM native builds.)
 - Prevent republish when there are no package changes.
