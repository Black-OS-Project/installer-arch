#!/bin/bash

# GPLv3 Copyright(c) Alim Koca

# First export definitions:
# LANG_SET: Language set for local
# LANG_KBD: Keyboard type
# DISK_TP: Disk type
# DISK_SWAP: Swap partition
# DISK_ROOT: Root partition
# DISK_EFI: EFI partition
# REGION: Region
# CITY: City of region
# HOSTNAME: Computer name
# USER_NM: Username of user
# DE: Desktop environment

loadkeys $LANG_KBD
ls /sys/firmware/efi/efivars

# Timedatectl settings
timedatectl set-ntp true

# Disk partitioning
cfdisk $DISK_TP

mkfs.ext4 $DISK_ROOT
mkswap $DISK_SWAP
mkfs.fat -F 32 $DISK_EFI

mount $DISK_ROOT /mnt
mkdir -p /mnt/boot
mount $DISK_EFI /mnt/boot

swapon $DISK_SWAP

# Installing packages for chroot
pacstrap /mnt base linux linux-firmware base-devel

# Configuring sytem
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt

ln -sf /usr/share/zoneinfo/$REGION/$CITY /etc/localtime
hwclock --systohc

# Localization
locale-gen

# LANG_SET: Sample: en_US-UTF-8
echo LANG=$LANG_SET > /etc/locale.conf
echo KEYMAP=$LANG_KBD > /etc/vconsole.conf

echo $HOSTNAME > /etc/hostname

# Initramfs
mkinitcpio -P

# Root password
passwd

# Bootloader setup
pacman –S grub
grub-install /dev/sda

# Creating user
useradd -mG wheel $USER_NM
usermod -aG wheel,audio,video,optical,storage $USER_NM
passwd $USER_NM
# Note: Please add your user to /etc/sudoers file after installation

if [ "$DE" = "xfce" ]; then
	echo "Installing xfce..."
	pacman -S xfce4 xfce4-goodies lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings network-manager-applet
	systemctl enable lightdm

elif [ "$DE" = "gnome" ]; then
	echo "Installing gnome..."
	pacman -S plasma plasma-wayland-session kde-applications sddm
	systemctl enable sddm

elif [ "$DE" = "plasma" ]; then
	echo "Installing kde plasma..."
	pacman -S gnome gnome-extra gdm
	systemctl enable gdm
else
	echo "Ahh, shit. Here we go again"
fi

# Network Manager
pacman -S NetworkManager
systemctl enable NetworkManager

# Reboot
reboot
