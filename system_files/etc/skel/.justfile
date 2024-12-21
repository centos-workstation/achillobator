install-system-flatpaks:
    @if ! flatpak remotes | grep -q flathub; then \
        flatpak remote-add --system flathub https://flathub.org/repo/flathub.flatpakrepo; \
    fi
    @flatpak --system -y install --or-update $(curl -s https://raw.githubusercontent.com/ublue-os/bluefin/main/bluefin_flatpaks/flatpaks | tr '\n' ' ')

brew-doctor:
    brew instal gcc
    ln -s /home/linuxbrew/.linuxbrew/bin/gcc-14 /home/linuxbrew/.linuxbrew/bin/gcc
    brew doctor
