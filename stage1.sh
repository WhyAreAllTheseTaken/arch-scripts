#!/usr/bin/bash

loadkeys uk
echo "Checking network"
ping ping.archlinux.org

echo "Updating time"
timedatectl

echo "Setting up disks..."
fdisk -l

read -p "Disk: " disk
fdisk $disk

read -p "Main: " partname 
pacman -S btrfs-progs
mkfs.btrfs -L boot $partname

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

packages=base linux linux-firmware btrfs-progs networkmanager neovim man-db man-pages texinfo

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

