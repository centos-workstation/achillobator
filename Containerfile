FROM quay.io/fedora/fedora-bootc:${MAJOR_VERSION:-41}

ARG IMAGE_NAME="${IMAGE_NAME:-achillobator}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-centos-workstation}"
ARG MAJOR_VERSION="${MAJOR_VERSION:-latest}"

RUN dnf update -y --setopt=fastestmirror=True --refresh
RUN dnf -y install \
-x PackageKit \
-x PackageKit-command-not-found \
-x gnome-software-fedora-langpacks \
 "NetworkManager-adsl" \
 "gdm" \
 "gnome-bluetooth" \
 "gnome-color-manager" \
 "gnome-control-center" \
 "gnome-initial-setup" \
 "gnome-remote-desktop" \
 "gnome-session-wayland-session" \
 "gnome-settings-daemon" \
 "gnome-shell" \
 "gnome-software" \
 "gnome-user-docs" \
 "gvfs-fuse" \
 "gvfs-goa" \
 "gvfs-gphoto2" \
 "gvfs-mtp" \
 "gvfs-smb" \
 "libsane-hpaio" \
 "nautilus" \
 "orca" \
 "ptyxis" \
 "sane-backends-drivers-scanners" \
 "xdg-desktop-portal-gnome" \
 "xdg-user-dirs-gtk" \
 "yelp-tools"

COPY system_files /
COPY build.sh /tmp/build.sh

RUN ln -sf /run /var/run

RUN mkdir -p /var/lib/alternatives && \
    /tmp/build.sh && \
    dnf clean all && \
    ostree container commit 

RUN bootc container lint
