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

fdisk -l
read -p "Main: " partname 
mkfs.btrfs -f -L system $partname

fdisk -l
read -p "Swap: " swapname 
mkswap $swapname

fdisk -l
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

packages="base git base-devel linux-hardened linux-firmware btrfs-progs networkmanager neovim sudo iptables zsh"

read -p "AMD? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
    packages="$packages intel-ucode"
then
    packages="$packages amd-ucode"
fi

echo "Installing base..."
pacstrap -K /mnt $packages
echo "Writing fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo "Copying stage2..."
cp ./stage2.sh /mnt/root/stage2.sh

echo "Copying stage3..."
cp ./stage3.sh /mnt/root/stage3.sh

arch-chroot /mnt /root/stage2.sh $efiname || true
swapoff $swapname

