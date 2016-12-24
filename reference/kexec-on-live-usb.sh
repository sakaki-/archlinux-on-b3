# Copyright (c) 2015 sakaki <sakaki@deciban.com>
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

echo "Creating patched zImage from archlinuxarm version..."
cat /boot/cache_head_patch /boot/zImage > zImage
echo "Loading patched kernel and setting command line..."
kexec --type=zImage --dtb=/boot/kirkwood-b3.dtb \
  --append="root=${ROOT} ${ROOTSPEC} rootdelay=${DELAY} ${CONSOLE}" \
  --load zImage
umount /boot
echo "Booting patched kernel with kexec..."
kexec -e
