#!/bin/bash
echo "Server=https://mirror.ufscar.br/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist;

echo "[options]
Architecture=auto
CheckSpace
ParallelDownloads=1
SigLevel=Required DatabaseOptional
LocalFileSigLevel=Optional
[core]
Include=/etc/pacman.d/mirrorlist
[extra]
Include=/etc/pacman.d/mirrorlist
[multilib]
Include=/etc/pacman.d/mirrorlist
[community]
Include=/etc/pacman.d/mirrorlist" > /etc/pacman.conf;

pacman -Syyu --noconfirm --quiet;

if fdisk /dev/nvme0n1; then <<EOF
o
w
EOF
fdisk /dev/nvme0n1 <<EOF
n
p
1

+2G
t
4
w
EOF
fdisk /dev/nvme0n1 <<EOF
n
p
2

+30G
w
EOF
fdisk /dev/nvme0n1 <<EOF
n
p
3


w
EOF
partprobe;
mkfs.fat -F32 /dev/nvme0n1p1;
mkfs.ext4 -F /dev/nvme0n1p2;
mkfs.ext4 -F /dev/nvme0n1p3;
mount /dev/nvme0n1p2 /mnt;
mkdir /mnt/boot;
mkdir /mnt/boot/EFI;
mkdir /mnt/home;
mount /dev/nvme0n1p1 /mnt/boot/EFI;
mount /dev/nvme0n1p3 /mnt/home;
else
fdisk /dev/sda <<EOF
o
w
EOF
fdisk /dev/sda <<EOF
n
p
1

+2G
t
4
w
EOF
fdisk /dev/sda <<EOF
n
p
2

+30G
w
EOF
fdisk /dev/sda <<EOF
n
p
3


w
EOF
partprobe;
mkfs.fat -F32 /dev/sda1;
mkfs.ext4 -F /dev/sda2;
mkfs.ext4 -F /dev/sda3;
mount /dev/sda2 /mnt;
mkdir /mnt/boot;
mkdir /mnt/boot/EFI;
mkdir /mnt/home;
mount /dev/sda1 /mnt/boot/EFI;
mount /dev/sda3 /mnt/home;
fi;

pacstrap /mnt --noconfirm \
base \
base-devel \
linux \
linux-firmware \
linux-headers \
networkmanager \
sudo \
git \
fastfetch \
grub-efi-x86_64 \
efibootmgr;

genfstab -U -p /mnt > /mnt/etc/fstab;

arch-chroot /mnt bash -c
echo 4RCH > /etc/hostname;

yes 4RCH | passwd root;

useradd -m -g users -G wheel 4RCH;

yes 4RCH | passwd 4RCH;

echo "pt_BR.UTF-8 UTF-8" > /etc/locale.gen;

echo "LANG=pt_BR.UTF-8" > /etc/locale.conf;

locale-gen;

hwclock --systohc;

echo "Server=https://mirror.ufscar.br/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist;

echo "alias i='yay -S --noconfirm --quiet'
alias d='sudo pacman -Rsc'
sudo rm -rf /home/4RCH/.bash_history /home/4RCH/.cache /var/log /tmp;
sudo pacman -Syyu --noconfirm --quiet;
sudo pacman -Scc --noconfirm --quiet;
clear;
fastfetch
cd / && sudo mv *.sh /home/4RCH && cd ~ && sudo chmod 777 *.sh && ./YAY.sh && ./PI-HOLE.sh && ./SSH.sh && sudo sed '$d' /home/4RCH/.bashrc" > /home/4RCH/.bashrc;

echo "[options]
Architecture=auto
CheckSpace
ParallelDownloads=1
SigLevel=Required DatabaseOptional
LocalFileSigLevel=Optional
[core]
Include=/etc/pacman.d/mirrorlist
[extra]
Include=/etc/pacman.d/mirrorlist
[multilib]
Include=/etc/pacman.d/mirrorlist
[community]
Include=/etc/pacman.d/mirrorlist" > /etc/pacman.conf;

pacman -Syyu --noconfirm --quiet;

if lspci | grep -i amd; then
pacman -Sy --noconfirm amd-ucode
fi;

if lspci | grep -i intel; then
pacman -Sy --noconfirm intel-ucode
fi;

if lspci | grep -i nvidia; then
pacman -Sy --noconfirm nvidia nvidia-dkms
fi;

if lspci | grep -i virtualbox; then
pacman -Sy --noconfirm \
virtualbox-guest-utils \
virtualbox-guest-modules-arch
fi;

systemctl enable NetworkManager

systemctl disable \
NetworkManager-wait-online \
systemd-networkd \
systemd-timesyncd;

mkinitcpio -P;

echo "GRUB_DEFAULT=0
GRUB_TIMEOUT=0
GRUB_DISTRIBUTOR=\"4RCH\"
GRUB_CMDLINE_LINUX_DEFAULT=\"quiet mitigations=off\"
GRUB_CMDLINE_LINUX=\"\"
GRUB_PRELOAD_MODULES=\"part_gpt part_msdos\"
GRUB_GFXMODE=auto
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_DISABLE_RECOVERY=true" > /etc/default/grub;

grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=4RCH --recheck;

grub-mkconfig -o /boot/grub/grub.cfg;

echo "4RCH ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers;

sed -i "/^\s*#/d; /^\s*$/d" \
/home/4RCH/.bash_profile \
/home/4RCH/.bash_logout \
/etc/sudoers \
/etc/sudo.conf \
/etc/host.conf \
/etc/healthd.conf \
/etc/mkinitcpio.conf \
/etc/libva.conf \
/etc/vconsole.conf \
/etc/fuse.conf \
/etc/ts.conf \
/etc/fstab;

sed -i "/^UUID=.* \/boot .*$/! s/rw/rw,noatime,discard,/" /etc/fstab;

echo "127.0.0.1 localhost.localdomain localhost
::1 localhost.localdomain localhost
127.0.0.1 4RCH.localdomain 4RCH" > /etc/hosts;

rm -rf /boot/initramfs-linux-fallback.img /mnt/ETAPA 2*;

sync;

reboot -f;
