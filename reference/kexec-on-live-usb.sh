# Copyright (c) 2015-7 sakaki <sakaki@deciban.com>
# License: GPL 3.0+
# NO WARRANTY

# This script fragment will be sourced by the initial (boot) kernel's
# init script; it must in turn load the DTB and final (target) kernel,
# setup the kernel command line, and finally pass control over to the
# new kernel with kexec -e.
# Remember that this script is running in a fairly minimal busybox
# environment, and that the shell is ash, not bash.

# On entry, /boot is already mounted (read-only).

# adjust the following to suit your system...
ROOT="PARTUUID=F8F07D53-03"
DELAY=5
ROOTSPEC="rootfstype=ext4"
CONSOLE="console=ttyS0,115200n8 earlyprintk"

echo "Ensuring Ethernet NICs are preserved..."
# set temporary spoof addresses, see
# https://forum.excito.com/viewtopic.php?p=28845#p28845
ifconfig eth0 10.250.251.252 netmask 255.255.255.255
ifconfig eth1 10.250.251.253 netmask 255.255.255.255

INITRAMFS="DONT_USE"
# uncomment below to use Arch's initramfs
# only needed for advanced users; serial console recommended
#INITRAMFS="/boot/initramfs-linux.img"

echo "Creating patched zImage from archlinuxarm version..."
cat /boot/cache_head_patch /boot/zImage > zImage
echo "Loading patched kernel and setting command line..."
if [ -f "${INITRAMFS}" ]; then
  kexec --type=zImage --dtb=/boot/kirkwood-b3.dtb \
    --initrd="${INITRAMFS}" \
    --append="root=${ROOT} ${ROOTSPEC} rootdelay=${DELAY} ${CONSOLE}" \
    --load zImage
else
  kexec --type=zImage --dtb=/boot/kirkwood-b3.dtb \
    --append="root=${ROOT} ${ROOTSPEC} rootdelay=${DELAY} ${CONSOLE}" \
    --load zImage
fi
umount /boot
echo "Booting patched kernel with kexec..."
kexec -e
