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

echo "Configuring sudo..."
mkdir -p /etc/sudoers.
echo "%wheel      ALL=(ALL:ALL) ALL" > /etc/sudoers.d/10-wheel

echo "Creating a user for makepkg..."
useradd -m -G wheel installer

echo "Installing yay..."
cd /home/installer
git clone https://aur.archlinux.org/yay-bin.git
chown -R installer yay-bin
cd yay-bin
su installer -c "makepkg -si"
cd ..
cd /root
echo "Removing makepkg user..."
userdel -r installer

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

