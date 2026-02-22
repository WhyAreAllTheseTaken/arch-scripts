#!/usr/bin/bash

set -e

loadkeys uk
echo "Checking network"
ip link
ping ping.archlinux.org || true

echo "Updating time"
timedatectl

echo "Installing dependencies..."
pacman --noconfirm -Sy btrfs-progs

echo "Setting up disks..."
fdisk -l

read -p "Disk: " disk
fdisk $disk

read -p "Main: " partname 
mkfs.btrfs -f -L system $partname

read -p "Swap: " swapname 
mkswap $swapname

read -p "EFI: " efiname 

read -p "Overwrite EFI? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    mkfs.fat -F 32 $efiname
fi

echo "Mounting..."
mount $partname /mnt
mount --mkdir $efiname /mnt/boot
swapon $swapname

packages=base linux-hardened linux-firmware btrfs-progs networkmanager neovim sudo iptables yay zsh

read -p "AMD? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
    packages=$packages intel-ucode
then
    packages=$packages amd-ucode
fi

echo "Installing base..."
pacstrap -K /mnt $packages
echo "Writing fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo "Copying stage2..."
cp ./stage2.sh /mnt/root/stage2.sh

arch-chroot /mnt /root/stage2.sh $efiname
unmount /mnt/boot
unmount /mnt
swapoff $swapname

