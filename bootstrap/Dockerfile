# Image used to create a rootfs using a pacstrap-like process.
FROM scratch
ADD _rootfs.tar.gz /

COPY mirrorlist /etc/pacman.d/mirrorlist
RUN set -xe \
 && pacman-key --init \
 && pacman-key --populate archlinux \
 && pacman --noconfirm -Suy tar gawk lua lua-luajson \
 && rm -r /var/lib/pacman/sync /var/cache/pacman/pkg /etc/pacman.d/gnupg

CMD ["/bin/bash"]
