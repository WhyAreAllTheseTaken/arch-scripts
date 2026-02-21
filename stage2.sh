#!/usr/bin/bash

efiname=$1

ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc
locale-gen
echo "LANG=en_GB.UTF-8" > /etc/locale.conf
echo "KEYMAP=uk" > /etc/vconsole.conf

read -p "Hostname: " hostname
echo $HOSTNAME > /etc/hostname

echo "Configuring root user"
passwd

echo "Setting up grub"
pacman -S grub efibootmgr grub-btrfs os-prober
grub-install --target=x86_64-efi --efi-directory=$efiname --removeable --bootloader-id=GRUB --modules="tpm" --disable-shim-lock
grub-mkconfig -o /boot/grub/grub.cfg


