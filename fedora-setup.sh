#!/bin/bash

if [ $EUID != 0 ]; then
    echo "Waiting for root privileges..."
    pkexec "$0" "$@"
    exit $?
fi

echo "Enabling RPM Fusion..."
dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || exit 1

lspci -v -m | grep VGA -A 7 | grep -e ^Vendor: | grep -q NVIDIA
$NVIDIA=$?

if [ "$NVIDIA" -eq 0 ]; then
    echo "NVIDIA card detected: installing drivers..."
    dnf -y install akmod-nvidia || exit 1
    dnf -y install xorg-x11-drv-nvidia-cuda vulkan || exit 1
else
    echo "No NVIDIA card detected, additional driver install not necessary."
fi

echo "Setting up multimedia..."
dnf -y swap ffmpeg-free ffmpeg --allowerasing
dnf -y update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin

# TODO: detect other gpu brands to set up hardware accel
if [ "$NVIDIA" -eq 0 ]; then
    echo "Installing NVIDIA hardware acceleration packages..."
    dnf -y install libva-nvidia-driver.{i686,x86_64} || exit 1
    dnf -y install xorg-x11-drv-nvidia-cuda vulkan || exit 1
fi

echo "Removing Fedora Flatpak repo and enabling Flathub..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || exit 1
flatpak remote-modify --no-filter --enable flathub || exit 1
flatpak install -y --reinstall flathub $(flatpak list --app-runtime=org.fedoraproject.Platform --columns=application | tail -n +1 ) || exit 1
flatpak remote-delete fedora || exit 1

echo "Installing Steam..."
dnf -y install steam || exit 1

echo ""
echo "All done!"
