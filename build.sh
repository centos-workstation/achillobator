#!/bin/bash

set -ouex pipefail

# Workarounds
mkdir -p /var/home
mkdir -p /var/roothome

# Image Info
OLD_PRETTY_NAME=$(bash -c 'source /usr/lib/os-release ; echo $NAME $VERSION')
MAJOR_VERSION=$(bash -c 'source /usr/lib/os-release ; echo $VERSION_ID')
IMAGE_PRETTY_NAME="Achillobator"
IMAGE_LIKE="rhel fedora"
HOME_URL="https://projectbluefin.io"
DOCUMENTATION_URL="https://docs.projectbluefin.io"
SUPPORT_URL="https://github.com/fedora-workstation/achillobator/issues/"
BUG_SUPPORT_URL="https://github.com/fedora-workstation/achillobator/issues/"
CODE_NAME="Dromaeosauridae"

IMAGE_INFO="/usr/share/ublue-os/image-info.json"
IMAGE_REF="ostree-image-signed:docker://ghcr.io/$IMAGE_VENDOR/$IMAGE_NAME"

image_flavor="main"
cat > $IMAGE_INFO <<EOF
{
  "image-name": "$IMAGE_NAME",
  "image-flavor": "$image_flavor",
  "image-vendor": "$IMAGE_VENDOR",
  "image-tag": "$MAJOR_VERSION",
  "fedora-version": "$MAJOR_VERSION"
}
EOF

# OS Release File (changed in order with upstream)
sed -i "s/^NAME=.*/NAME=\"$IMAGE_PRETTY_NAME\"/" /usr/lib/os-release
sed -i "s|^VERSION_CODENAME=.*|VERSION_CODENAME=\"$CODE_NAME\"|" /usr/lib/os-release
sed -i "s/^ID=fedora/ID=${IMAGE_PRETTY_NAME,}\nID_LIKE=\"${IMAGE_LIKE}\"/" /usr/lib/os-release
sed -i "s/^VARIANT_ID=.*/VARIANT_ID=$IMAGE_NAME/" /usr/lib/os-release
sed -i "s/^PRETTY_NAME=.*/PRETTY_NAME=\"${IMAGE_PRETTY_NAME} $MAJOR_VERSION (FROM $OLD_PRETTY_NAME)\"/" /usr/lib/os-release
sed -i "s|^HOME_URL=.*|HOME_URL=\"$HOME_URL\"|" /usr/lib/os-release
echo "DOCUMENTATION_URL=\"$DOCUMENTATION_URL\"" | tee -a /usr/lib/os-release
echo "SUPPORT_URL=\"$SUPPORT_URL\"" | tee -a /usr/lib/os-release
sed -i "s|^BUG_REPORT_URL=.*|BUG_REPORT_URL=\"$BUG_SUPPORT_URL\"|" /usr/lib/os-release
sed -i "s|^CPE_NAME=\"cpe:/o:fedora:fedora|CPE_NAME=\"cpe:/o:universal-blue:${IMAGE_PRETTY_NAME,}|" /usr/lib/os-release
echo "DEFAULT_HOSTNAME=\"${IMAGE_PRETTY_NAME,,}\"" | tee -a /usr/lib/os-release
sed -i "/^REDHAT_BUGZILLA_PRODUCT=/d; /^REDHAT_BUGZILLA_PRODUCT_VERSION=/d; /^REDHAT_SUPPORT_PRODUCT=/d; /^REDHAT_SUPPORT_PRODUCT_VERSION=/d" /usr/lib/os-release

if [[ -n "${SHA_HEAD_SHORT:-}" ]]; then
  echo "BUILD_ID=\"$SHA_HEAD_SHORT\"" >> /usr/lib/os-release
fi

# Fix issues caused by ID no longer being rhel??? (FIXME: check if this is necessary)
sed -i "s/^EFIDIR=.*/EFIDIR=\"rhel\"/" /usr/sbin/grub2-switch-to-blscfg

KERNEL_SUFFIX=""
QUALIFIED_KERNEL="$(rpm -qa | grep -P 'kernel-(|'"$KERNEL_SUFFIX"'-)(\d+\.\d+\.\d+)' | sed -E 's/kernel-(|'"$KERNEL_SUFFIX"'-)//')"
/usr/bin/dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible --zstd -v --add ostree -f "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"

# Additions
dnf -y install --setopt=install_weak_deps=False install \
    distrobox \
    dnf5-plugins \
    gnome-shell-extension-appindicator \
    gnome-shell-extension-dash-to-dock \
    gnome-tweaks \
    tuned-ppd \
    systemd-container \
    gnome-shell-extension-blur-my-shell \
    fastfetch \
    just \
    tailscale \
    gcc \
    git




dnf config-manager addrepo --from-repofile="https://copr.fedorainfracloud.org/coprs/ublue-os/staging/repo/fedora-${MAJOR_VERSION}/ublue-os-staging-fedora-${MAJOR_VERSION}.repo"
dnf -y --enablerepo copr:copr.fedorainfracloud.org:ublue-os:staging --setopt=install_weak_deps=False install \
  -x bluefin-logos \
  gnome-shell-extension-logo-menu \
  uupd \
  bluefin-*

dnf -y --enablerepo copr:copr.fedorainfracloud.org:ublue-os:staging swap fedora-logos bluefin-logos

rm -f /usr/share/pixmaps/faces/* || echo "Expected directory deletion to fail"
mv /usr/share/pixmaps/faces/bluefin/* /usr/share/pixmaps/faces
rm -rf /usr/share/pixmaps/faces/bluefin

dnf config-manager addrepo --from-repofile="https://copr.fedorainfracloud.org/coprs/che/nerd-fonts/repo/fedora-${MAJOR_VERSION}/che-nerd-fonts-fedora-${MAJOR_VERSION}.repo"
dnf -y --enablerepo copr:copr.fedorainfracloud.org:che:nerd-fonts install \
  nerd-fonts

#Disable all repos on F41


# Homebrew
touch /.dockerenv
curl --retry 3 -Lo /tmp/brew-install https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
chmod +x /tmp/brew-install
/tmp/brew-install
tar --zstd -cvf /usr/share/homebrew.tar.zst /home/linuxbrew
rm -f /.dockerenv
# Clean up brew artifacts on the image.
rm -rf /home/linuxbrew /root/.cache

# Services
systemctl enable dconf-update.service
# Forcefully enable brew setup since the preset doesnt seem to work?
systemctl enable brew-setup.service
systemctl disable mcelog.service
systemctl enable tailscaled.service
systemctl enable uupd.timer
systemctl disable bootc-fetch-apply-updates.timer bootc-fetch-apply-updates.service
