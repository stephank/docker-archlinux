# Image used to create a rootfs using a pacstrap-like process.
FROM scratch
ADD _rootfs.tar.gz /

COPY mirrorlist /etc/pacman.d/mirrorlist
RUN set -xe \
 && pacman-key --init \
 && pacman-key --populate archlinux \
 && perl -ne 'gethostbyname($1) if /^Server = https?:\/\/(.+)\//' < /etc/pacman.d/mirrorlist \
 && pacman --noconfirm -Sy tar \
 && rm -r /var/lib/pacman/sync /var/cache/pacman/pkg /etc/pacman.d/gnupg

COPY entry.sh /
CMD ["/entry.sh"]
