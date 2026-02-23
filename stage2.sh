#!/usr/bin/bash

set -e

efiname=$1

ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc
locale-gen
echo "en_GB.UTF8" >> /etc/locale.gen
locale-gen
echo "LANG=en_GB.UTF-8" > /etc/locale.conf
echo "KEYMAP=uk" > /etc/vconsole.conf

read -p "Hostname: " hostname2
echo $hostname2 > /etc/hostname

echo "Configuring sudo..."
mkdir -p /etc/sudoers.
echo "%wheel      ALL=(ALL:ALL) ALL" > /etc/sudoers.d/10-wheel
echo "installer   ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/20-installer

echo "Creating a user for makepkg..."
useradd -m installer

echo "Installing paru..."
cd /tmp
git clone https://aur.archlinux.org/paru.git
chown -R installer paru
cd paru
su installer -c "makepkg -si"
cd /root
echo "Removing makepkg user"
userdel -r installer
rm /etc/sudoers.d/20-installer
rm -rfv /tmp/paru

echo "Configuring paru..."
paru --gendb

echo "Setting up grub..."
paru --noconfirm -Sy grub efibootmgr grub-btrfs os-prober
grub-install --target=x86_64-efi --efi-directory=/boot --removable --bootloader-id=GRUB --modules="tpm" --disable-shim-lock
grub-mkconfig -o /boot/grub/grub.cfg

echo "Configuring username..."
read -p "Username: " username
useradd -m -G wheel -s /usr/bin/zsh $username
echo "Configuring user password..."
passwd $username

echo "Disabling root login..."
passwd -l root

echo "Adding login delay on fail..."
echo "auth optional pam_faildelay.so delay=1000000" >> /etc/pam.d/system-login

echo "Reboot, login, and then run 'sudo /root/stage3.sh' to complete setup.";


