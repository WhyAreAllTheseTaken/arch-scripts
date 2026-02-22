#!/usr/bin/bash

set -e

efiname=$1

ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc
locale-gen
echo "LANG=en_GB.UTF-8" > /etc/locale.conf
echo "KEYMAP=uk" > /etc/vconsole.conf

read -p "Hostname: " hostname
echo $HOSTNAME > /etc/hostname

echo "Installing yay..."
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si
cd ..
echo "Configuring yay..."
yay -Y --gendb
yay -Y --devel --save

echo "Setting up grub..."
pacman -Sy grub efibootmgr grub-btrfs os-prober
grub-install --target=x86_64-efi --efi-directory=$efiname --removable --bootloader-id=GRUB --modules="tpm" --disable-shim-lock
grub-mkconfig -o /boot/grub/grub.cfg

echo "Configuring next boot..."
echo "/root/stage3.sh" >> /root/.bashrc

echo "Rebooting..."
systemctl reboot

