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

echo "Configuring firewall..."
iptables -N TCP
iptables -N UDP
iptables -P OUTPUT ACCEPT
iptables -P INPUT DROP
# Allow connections we have already opened
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# Allow loopback
iptables -A INPUT -i lo -j ACCEPT
# Deny invalid
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
# Allow ping
iptables -A INPUT -p icmp --icmp-type 8 -m conntrack --ctstate NEW -j ACCEPT
# Connect chains
iptables -A INPUT -p udp -m conntrack --ctstate NEW -j UDP
iptables -A INPUT -p tcp --syn -m conntrack --ctstate NEW -j TCP
# Reject unknown ports
iptables -A INPUT -p udp -j REJECT --reject-with icmp-port-unreachable
iptables -A INPUT -p tcp -j REJECT --reject-with tcp-reset
# Reject unknown protocols.
iptables -A INPUT -j REJECT --reject-with icmp-proto-unreachable
# Allow SSH
iptables -A TCP -p tcp --dport 22 -j ACCEPT
iptables-save -f /etc/iptables/iptables.rules
echo "Configuring IPv6 firewall..."
ip6tables -A INPUT -p ipv6-icmp --icmpv6-type 128 -m conntrack --ctstate NEW -j ACCEPT
ip6tables -A INPUT -s fe80::/10 -p ipv6-icmp -j ACCEPT
ip6tables -A INPUT -p udp --sport 547 --dport 546 -j ACCEPT
ip6tables-save -f /etc/iptables/ip6tables.rules

cp /etc/iptables/iptables.rules /etc/iptables/ip6tables.rules

echo "Final rules:"
cat /etc/iptables/iptables.rules
cat /etc/iptables/ip6tables.rules

echo "Starting firewall"
systemctl enable iptables.service
systemctl enable ip6tables.service
systemctl start iptables.service
systemctl start ip6tables.service

echo "Configuring yay..."
yay -Y --devel --save

echo "Configuring sudo..."
echo "%wheel      ALL=(ALL:ALL) ALL" > /etc/sudoers.d/10-wheel

echo "Configuring users..."
read -p "Username: " username
useradd -m -G wheel -s /usr/bin/zsh $username
passwd $username

echo "Disabling root login..."
passwd -l root

echo "Adding login delay on fail..."
echo "auth optional pam_faildelay.so delay=1000000" > /etc/pam.d/system-login

echo "Setting up grub..."
pacman -Sy grub efibootmgr grub-btrfs os-prober
grub-install --target=x86_64-efi --efi-directory=$efiname --removable --bootloader-id=GRUB --modules="tpm" --disable-shim-lock
grub-mkconfig -o /boot/grub/grub.cfg

