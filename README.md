# archlinux-on-b3

Bootable live-USB of Arch Linux for the Excito B3 miniserver, with Linux 3.17.1

<img src="https://raw.githubusercontent.com/sakaki-/resources/master/excito/b3/Excito_b3.jpg" alt="Excito B3" width="250px" align="right"/>
This project contains a bootable, live-USB image for the Excito B3 miniserver. You can use it as a rescue disk, to play with Arch Linux, or as the starting point to install Arch Linux on your B3's main hard drive. You can even use it on a diskless B3. No soldering, compilation, or [U-Boot](http://www.denx.de/wiki/U-Boot/WebHome) flashing is required! You can run it without harming your B3's existing software; however, any changes you make while running the system *will* be saved to the USB (i.e., there is persistence).

The kernel used in the image is **3.17.1**, with the necessary code to temporarily switch off the L2 cache in early boot (per [this link](https://lists.debian.org/debian-boot/2012/08/msg00804.html)) prepended, and the kirkwood-b3 device tree blob appended (which is why you don't have to reflash your U-Boot to use it). The `.config` used for the kernel may be found [here](https://github.com/sakaki-/archlinux-on-b3/blob/master/configs/b3_live_usb_config) in the git archive.

The image may be downloaded from the link below (or via `wget`, per the following instructions).
> Note that this differs slightly from its sister [gentoo-on-b3 project](https://github.com/sakaki-/gentoo-on-b3), in that there is only a *single* image supplied. Accordingly, if you wish to use this image in a 'diskless' chassis, you will need to make a few small changes before booting, which are detailed later in these notes.

Variant | Image | Digital Signature
:--- | ---: | ---:
B3 with or without Internal Drive | [archb3img.xz](https://github.com/sakaki-/archlinux-on-b3/releases/download/1.0.0/archb3img.xz) | [archb3img.xz.asc](https://github.com/sakaki-/archlinux-on-b3/releases/download/1.0.0/archb3img.xz.asc)

> Please read the instructions below before proceeding. Also please note that the image is provided 'as is' and without warranty. And also, since it is largely based on the 3 Oct 2014 Kirkwood image from [archlinuxarm.org](http://archlinuxarm.org), please refer to that site for licensing details of firmware files etc.

## Prerequisites

To try this out, you will need:
* A USB key of at least 4GB capacity. Unfortunately, not all USB keys work with the version of [U-Boot](http://www.denx.de/wiki/U-Boot/WebHome) on the B3 (2010.06 on my device). I have tested it successfully with SanDisk Cruzer 4GB and 8GB USB keys, but some larger devices (e.g. 32GB Verbatim keys) do not work.
* An Excito B3 (obviously!). As shipped, the image assumes you have an internal hard drive fitted; if using a diskless chassis, be sure to follow the instructions given later, before attempting to boot.
* A PC to decompress the appropriate image and write it to the USB key (of course, you can also use your B3 for this, assuming it is currently running the standard Excito / Debian Squeeze system). This is most easily done on a Linux machine of some sort, but tools are also available for Windows (see [here](http://tukaani.org/xz/) and [here](http://sourceforge.net/projects/win32diskimager/), for example). In the instructions below I'm going to assume you're using Linux.

## Downloading and Writing the Image

On your Linux box, issue:
```
# wget -c https://github.com/sakaki-/archlinux-on-b3/releases/download/1.0.0/archb3img.xz
# wget -c https://github.com/sakaki-/archlinux-on-b3/releases/download/1.0.0/archb3img.xz.asc
```
to fetch the compressed disk image file (151MiB) and its signature.

Next, if you like, verify the image using `gpg` (this step is optional):
```
# gpg --keyserver pool.sks-keyservers.net --recv-key DDE76CEA
# gpg --verify archb3img.xz.asc archb3img.xz
```

Assuming that reports 'Good signature', you can proceed.

Next, insert (into your Linux box) the USB key on which you want to install the image, and determine its device path (this will be something like `/dev/sdb`, `/dev/sdc` etc.; the actual path will depend on your system, you can use the `lsblk` tool to help you). Unmount any existing partitions of the USB key that may have automounted (using `umount`). Then issue:

> **Warning** - this will *destroy* all existing data on the target drive, so please double-check that you have the path correct!

```
# xzcat archb3img.xz > /dev/sdX && sync
```

Substitute the actual USB key device path, for example `/dev/sdc`, for `/dev/sdX` in the above command. Make sure to reference the device, **not** a partition within it (so e.g., `/dev/sdc` and not `/dev/sdc1`; `/dev/sdd` and not `/dev/sdd1` etc.)

The above `xzcat` to the USB key will take some time, due to the decompression (it takes between 5 and 15 minutes on my machine, depending on the USB key used). It should exit cleanly when done - if you get a message saying 'No space left on device', then your USB key is too small for the image, and you should try again with a larger capacity one.

## Specifying Required Network Settings

The Archlinux system on the image will setup the `eth0` network interface on boot (this uses the **wan** Ethernet port on the B3). However, before networking is started, it will attempt to read a file from the first partition of the USB key, namely `/install/wan`; if found, this will be used to *overwrite* the file `/etc/netctl/wan` on the USB root (in the USB key's second partition). Therefore, you can edit this file to specify settings appropriate for your network.

In the image, `/install/wan` initially contains:
> 
```
Description='WAN Port on B3'
Interface=eth0
Connection=ethernet
IP=static
Address=('192.168.1.129/24')
Gateway='192.168.1.254'
DNS=('8.8.8.8')
SkipNoCarrier=yes
```

That is, as shipped, the Arch Linux system will attempt to bring up the eth0 (**wan**) Ethernet interface, with a fixed address of 192.168.1.129 (NB - this is different from the default [gentoo-on-b3](https://github.com/sakaki-/gentoo-on-b3) address), netmask 255.255.255.0 (the '/24' in Address = 24 bits of mask), broadcast address 192.168.1.255 (implied) and gateway 192.168.1.254, using Google's DNS nameserver at 8.8.8.8. If these settings are not appropriate for your network, edit this file as required (note that you will have to specify a fixed address at this stage; later, when you are logged into the system, you can configure DHCP etc. if desired). The first USB partition is formatted `fat16` and so the edits can be made on any Windows box; or, if using Linux:
```
# mkdir /tmp/mntusb
# mount -v /dev/sdX1 /tmp/mntusb
# nano -w /tmp/mntusb/install/wan
  <make changes as needed, and save>
# sync
# umount -v /tmp/mntusb
# rmdir /tmp/mntusb
```

Obviously, substitute the appropriate path for `/dev/sdX1` in the above. If your USB key is currently on `/dev/sdc`, you'd use `/dev/sdc1`; if it is on `/dev/sdd`, you'd use `/dev/sdd1`, etc.

## Select Alternative Kernel (*Only* for B3s with no Hard Drive)

Next, if (and **only** if) you are using a B3 without an internal hard drive fitted, you will need switch the kernel used on the USB key, or your Arch Linux system will fail to boot. 
> Users of standard B3s (which have an internal hard drive, running the normal Excito system), can (and should) skip this step - the shipped image already has the correct kernel (and `fstab`) in place for you. Continue reading at "Booting!", below.

Specifically, users of diskless B3s will need to:
* rename the shipped kernel `/install/install.itb` (on the USB key's first partition) to something else (`/install/install_withdisk.itb`, for example); and then
* rename the supplied `/install/install_diskless.itb` to `/install/install.itb`; and then
* modify the `/etc/fstab` file (on the USB key's second partition), so that the correct drive is specified.

You need only make these changes once. Assuming you are using Linux:
```
# mkdir /tmp/mntusb
# mount -v /dev/sdX1 /tmp/mntusb
# mv /tmp/mntusb/install/install.itb /tmp/mntusb/install/install_withdisk.itb
# mv /tmp/mntusb/install/install_diskless.itb /tmp/mntusb/install/install.itb
# sync
# umount -v /tmp/mntusb
# mount -v /dev/sdX2 /tmp/mntusb
# sed -i s/sdb/sda/g /tmp/mntusb/etc/fstab
# sync
# umount -v /tmp/mntusb
# rmdir /tmp/mntusb
```

Obviously, substitute the appropriate path for `/dev/sdX1` and `/dev/sdX2` in the above. If your USB key is currently on `/dev/sdc`, you'd use `/dev/sdc1` and `/dev/sdc2`; if it is on `/dev/sdd`, you'd use `/dev/sdd1` and `/dev/sdd2`, etc.

## Booting!

All done, you are now ready to try booting your B3!

Begin with your B3 powered off and the power cable removed. Insert the USB key into either of the USB slots on the back of the B3, and make sure the other USB slot is unoccupied. Connect the B3 to your local network using the **wan** Ethernet port. Then, *while holding down the button on the back of the B3*, apply power (insert the power cable). After two seconds or so, release the button. If all is well, the B3 should boot the kernel off of the USB key (rather than the internal drive), and then proceed to mount the root partition (also from the USB key) and start Arch Linux. This will all take about 40 seconds or so. The LED on the front of the B3 should first turn green, then turn off for about 20 seconds, and then turn green again as Arch Linux comes up.

## Connecting to the B3

Once booted, you can log into the B3 from any other machine on your subnet (the root password is **root**). Issue:
```
> ssh root@192.168.1.129
The authenticity of host '192.168.1.129 (192.168.1.129)' can't be established.
ED25519 key fingerprint is 30:04:59:a6:cf:e6:bb:c2:ea:53:53:b3:2a:fa:88:d2.
Are you sure you want to continue connecting (yes/no)? <type yes and press Enter>
Warning: Permanently added '192.168.1.129' (ED25519) to the list of known hosts.
root@192.168.1.129's password: <type root and press Enter>
[root@archb3 ~]# 
```
and you're in! Obviously, substitute the correct network address for your B3 in the command above (if you changed it in `/install/wan`, earlier). Also, note that you may receive a different fingerprint type, depending on what your `ssh` client supports. The `ssh` host key fingerprints on the image are as follows:
> 
```
1024 85:0b:a1:2e:8b:75:d0:1a:58:d5:88:0e:57:4b:a9:6f  root@archb3 (DSA)
256 fb:e2:58:b2:a2:3b:19:1d:35:3f:03:05:23:87:ff:26  root@archb3 (ECDSA)
256 30:04:59:a6:cf:e6:bb:c2:ea:53:53:b3:2a:fa:88:d2  root@archb3 (ED25519)
2048 7b:16:61:49:4a:44:02:d4:18:31:57:c8:ab:25:dc:48  root@archb3 (RSA1)
2048 1a:ef:d7:61:b5:83:e4:e1:44:88:36:75:90:42:38:0c  root@archb3 (RSA)
```

If you have previously connected to a *different* machine with the *same* IP address as your B3 via `ssh` from the client PC, you may need to delete its host fingerprint (from `~/.ssh/known_hosts` on the PC) before `ssh` will allow you to connect.

## Using Arch Linux

The supplied image contains a configured Arch Linux system, based on the 3 Oct 2014 `ArchLinuxARM-kirkwood-latest.tar.gz` image from the [archlinuxarm.org repo](http://archlinuxarm.org/os/), so you can immediately perform `pacman` operations (Arch Linux's equivalent of `apt-get`) etc. See the section "Keeping Your Arch Linux System Up-To-Date" near the end of this document.

Be aware that, as shipped, it has a UTC timezone and no system locale; however, these are easily changed if desired. See the [Arch Linux Beginners' Guide](https://wiki.archlinux.org/index.php/beginners'_guide) for details.

The drivers for WiFi (if you have the hardware on your B3) *are* present, but configuration of WiFi in master mode (using hostapd) is beyond the scope of this short write up (see [here](http://nims11.wordpress.com/2012/04/27/hostapd-the-linux-way-to-create-virtual-wifi-access-point/) for some details). The wifi interface name is `wlp1s0`. Similarly, the **lan** port can be accessed via `eth1`, but is not currently set to come up on boot. You can modify the behaviour as you like using the `netctl` utility; see [these notes](https://wiki.archlinux.org/index.php/netctl) for example. There is also some useful information about `netctl`, bridging etc. on [this wiki page](http://wiki.mybubba.org/wiki/index.php?title=Running_Arch_Linux#The_netctl_way).

Once you have networking set up as you like it, you can issue:
```
[root@archb3 ~]# systemctl disable copynetsetup 
```
to prevent your `wan` settings being overwritten again by the file in the first USB partition, next time you boot.

When you are done using your Arch Linux system, you can simply issue:
```
[root@archb3 ~]# systemctl reboot
```
and your machine will cleanly restart back into your existing (Excito) system off the hard drive. At this point, you can remove the USB key if you like. You can then, at any later time, simply repeat the 'power up with USB key inserted and button pressed' process to come back into Arch Linux - any changes you made will still be present on the USB key.

Also, please note that there is no handler bound to the rear-button press events in the shipped system, so if you want to power off cleanly (rather than rebooting), issue: 
```
[root@archb3 ~]# systemctl poweroff
```
Wait a few seconds after the green LED turns off before physically removing power.

Have fun! ^-^

## Erratum

At the time of writing, there is an ongoing issue with the Marvell Ethernet driver for kernels >= 3.16. As I discuss [here](http://forum.mybubba.org/viewtopic.php?f=7&t=5738), this can cause data corruption when performing large data transfers on the B3. This will presumably be fixed upstream eventually, but for now, you should implement the following small workaround when running Arch on your B3 (incidentally, this workaround has already been put in place for you in the latest [Gentoo live-USB](https://github.com/sakaki-/gentoo-on-b3) image for the B3, but did not make it into this release for Arch, so you'll need to do it yourself, as detailed next).

Begin by updating your package metadata, then downloading the `ethtool` software. Issue:
```
[root@archb3 ~]# pacman -Sy
   (confirm if prompted)
[root@archb3 ~]# pacman -S ethtool
   (confirm if prompted)
```

Now, create a udev rule to turn off TCP segmentation offload (`tso`) for the B3's ethernet ports:
```
[root@archb3 ~]# nano -w /etc/udev/rules.d/50-marvell-fix-tso.rules
```

and place the following text in that file:
```
# Disable Marvell TCP segmentation offload due to bugs
# See e.g. http://archlinuxarm.org/forum/viewtopic.php?f=9&t=7692&start=20
ACTION=="add", SUBSYSTEM=="net", KERNEL=="eth[0-1]", RUN+="/usr/sbin/ethtool -K %k tso off"
```

Save, and exit `nano`. When you next reboot your B3, `tso` will be disabled (you only need to set up this workaround once).

## Miscellaneous Points

* The specific B3 devices (LEDs, buzzer, rear button etc.) are now described by the file `arch/arm/boot/dts/kirkwood-b3.dts` in the main kernel source directory (and included in the git archive too, for reference). You can see an example of using the defined devices in `/etc/systemd/system/bootled.service`, which turns on the green LED as Arch Linux starts up, and off again on shutdown (this replaces the previous [approach](http://wiki.mybubba.org/wiki/index.php?title=Let_your_B3_beep_and_change_the_LED_color), which required an Excito-patched kernel).
* The live USB works because the B3's firmware boot loader will automatically try to run a file called `/install/install.itb` from the first partition of the USB drive when the system is powered up with the rear button depressed. In the provided image, we have placed a bootable kernel in that location, with an internal command line set to `root=/dev/sdb2 rootfstype=ext4 rootdelay=5 console=ttyS0,115200n8 earlyprintk`. (The 'diskless' variant uses a command line of `root=/dev/sda2 rootfstype=ext4 rootdelay=5 console=ttyS0,115200n8 earlyprintk`.) Despite the name, no 'installation' takes place, of course!
* If you have a USB key larger than the minimum 4GB, after writing the image you can easily extend the size of the second partition (using `fdisk` and `resize2fs`), so you have more space to work in. See [these instructions](http://geekpeek.net/resize-filesystem-fdisk-resize2fs/), for example.

## Installing Arch Linux on your B3's Internal Drive (Optional)

If you like Arch Linux, and want to set it up permanently on the B3's internal hard drive, you can do so easily (it takes less than 5 minutes). The full process is described below. (Note, this is strictly optional, you can simply run Arch Linux from the USB key, if you are just experimenting, or using it as a rescue system.)

> **Warning** - the below process will wipe all existing software and data from your internal drive, so be sure to back that up first, before proceeding.

OK, first, boot into the image and then connect to your B3 via `ssh`, as described above. Then, configure the partition table on your hard drive, as described below (**warning** - this will delete all data and software on there, including your existing Excito system, so only proceed if you are sure). We'll make three partitions, for boot, swap and root (feel free to adopt a different scheme if you like; however, note that you will have to recompile your kernel unless targeting a `root` on `/dev/sda3`):
```
[root@archb3 ~]# fdisk /dev/sda
<press o and Enter (to create a new disk label)>
<press n and Enter (to create a new partition)>
<press Enter (to make a primary partition)>
<press Enter (to define partition 1)>
<press Enter (to accept the default start location)>
<type +32M and press Enter (to make a 32MiB sector, for boot)>
<type a and press Enter (to turn the boot flag on)>
<press n and Enter (to create a new partition)>
<press Enter (to make a primary partition)>
<press Enter (to define partition 2)>
<press Enter (to accept the default start location)>
<type +1G and press Enter (to make a 1GiB sector, for swap)>
<type t and press Enter (to change the sector type)>
<press Enter (to accept changing partition 2's type)>
<type 82 and press Enter (to set the type as swap)>
<type n and press Enter (to create a new partition)>
<press Enter (to make a primary partition)>
<press Enter (to define partition 3)>
<press Enter (to accept the default start location)>
<press Enter (to use all remaining space on the drive)>
<type p and press Enter (to review the partition table)>
<type w and press Enter (to write the table and exit)>
```

Next, format the partitions (NB, do **not** use `ext4` for the boot partition (`/dev/sda1`), as older versions of U-Boot will not be able to read it):
```
[root@archb3 ~]# mkfs.ext3 /dev/sda1
[root@archb3 ~]# mkswap /dev/sda2
[root@archb3 ~]# mkfs.ext4 /dev/sda3
```

Now, we need to copy the necessary system information. I have provided a second version of the kernel (in `root`'s home directory) that looks for its `root` partition on `/dev/sda3`, and has no `rootdelay` (but is otherwise identical to the one on the USB key you booted off), so you need to copy that across:
```
[root@archb3 ~]# mkdir /mnt/{sdaboot,sdaroot}
[root@archb3 ~]# mount /dev/sda1 /mnt/sdaboot
[root@archb3 ~]# mount /dev/sda3 /mnt/sdaroot
[root@archb3 ~]# mkdir /mnt/sdaboot/boot
[root@archb3 ~]# cp /root/root-on-sda3-kernel/{uImage,config} /mnt/sdaboot/boot/
```
Note that this kernel will be booted *without* the button pressed down, so it needs to live in the special path `/boot/uImage` on the first partition (which is where we just copied it (along with its `config`), by means of the last command, above).

Next, we'll set up the `root` partition itself. The process below isn't quite what your mother would recommend ^-^, but it gets the job done (the first line may take some time to complete):
```
[root@archb3 ~]# cp -ax /bin /dev /etc /lib /root /sbin /srv /tmp /usr /var /mnt/sdaroot/
[root@archb3 ~]# mkdir /mnt/sdaroot/{boot,home,mnt,opt,proc,run,sys}
```

Since we simply copied over the `/etc/fstab` file, it will be wrong; a valid copy (for use when booting off the internal drive) is present in `root`'s home directory on the USB image. Copy it over now:
```
[root@archb3 ~]# cp /root/fstab-on-b3 /mnt/sdaroot/etc/fstab
```
Finally, `sync` the filesystem, and unmount:
```
[root@archb3 ~]# sync
[root@archb3 ~]# umount -l /mnt/{sdaboot,sdaroot}
[root@archb3 ~]# rmdir /mnt/{sdaboot,sdaroot}
```

That's it! You can now try rebooting your new system (it will have the same initial network settings as the USB version, since we've just copied them over). Issue:
```
[root@archb3 ~]# systemctl reboot
```
And let the system shut down and come back up. **Don't** press the B3's back-panel button this time. The system should boot directly off the hard drive. You can now remove the USB key, if you like, as it's no longer needed. Wait 30 seconds or so, then from your PC on the same subnet issue:
```
> ssh root@192.168.1.129
root@192.168.1.129's password: <type root and press Enter>
[root@archb3 ~]# 
```
Of course, use whatever IP address you assigned earlier, rather than `192.168.1.129` in the above. Also, if you changed root's password in the USB image, use that new password rather than `root` in the above.

Once logged in, feel free to configure your system as you like! Of course, if you're intending to use the B3 as an externally visible server, you should change the `ssh` host keys, change `root`'s password, install a firewall etc.

### Recompiling the Kernel (Optional)

Note that the kernel on this image is *not* the standard Arch Linux armv5te variant provided by [archlinuxarm.org](http://archlinuxarm.org). To ensure compatibility with the older U-Boot bootloaders found on many B3s, the shipped kernel:
* contains a fixed kernel command line (to ensure that the `root` partition is properly specified, and that a `rootdelay` of 5 seconds is used when booting from USB); and
* has some machine code prepended to temporarily turn of the L2 caches during boot (per [this workaround](https://lists.debian.org/debian-boot/2012/08/msg00804.html)); and
* has the DTB (device tree blob) for the B3 appended to the kernel image (and the kernel config used has `CONFIG_ARM_APPENDED_DTB=y` set).

Accordingly, while you can absolutely use `pacman` to update any of the *userland* software on your Arch Linux B3, if you want to update the kernel, you need to build it yourself.

> Recompiling the kernel is *not* necessary for day-to-day usage of your Arch Linux system. These instructions have been provided only in the interest of completeness.

Building a kernel is a straightforward process, but will take about 4-5 hours on the B3, which is not a particularly fast machine. Note also that you **must** build at least version 3.17 of the kernel, if you wish to use the shipped kernel's configuration as a basis (the organization of kirkwood in the kernel having changed considerably in 3.17; see [this post](http://forum.mybubba.org/viewtopic.php?f=7&t=5680)). You should also only do this from an installation on the B3's internal drive, as it requires quite a bit of disk space.

OK, so suppose you wish to build 3.17.1 (the same version as supplied in the image), using the standard ([kernel.org](https://www.kernel.org/)) sources. Then you could proceed as follows. 

First, if you haven't already, ensure that you have the necessary build software (`gcc` etc.) on your B3, using `pacman` (this is a one-off step):
```
[root@archb3 ~]# pacman -Sy
[root@archb3 ~]# pacman -S abs bc uboot-mkimage
   (confirm when prompted)
[root@archb3 ~]# pacman -S base-devel
   (you can pick which items to install, or, most simply, just press
    <Enter> when prompted with the numbered list, to install all
    software in the group base-devel)
```

Next, fetch the required kernel, and unpack it:
```
[root@archb3 ~]# curl -O https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.17.1.tar.xz
   (this will take some time to complete, depending on your network connection)
[root@archb3 ~]# unxz linux-3.17.1.tar.xz
   (at this point, you can download the .sig file and gpg --verify, if you like)
[root@archb3 ~]# tar xf linux-3.17.1.tar
[root@archb3 ~]# cd linux-3.17.1
```

Pull a kernel config from the currently running kernel, and sanitize it:
```
[root@archb3 linux-3.17.1]# zcat /proc/config.gz > .config
[root@archb3 linux-3.17.1]# make olddefconfig
```

Optionally, make any changes you like to the kernel configuration using the editor:
```
[root@archb3 linux-3.17.1]# make menuconfig
```

Lastly, build the kernel and modules, then deploy the modules to `/lib/modules`, patch the kernel appropriately and place the resulting uImage in the `boot` partition's `/boot` directory. I have supplied a script, `/root/prep_arm_image_on_b3.sh` which will do all this for you. So, to build, simply issue:

```
[root@archb3 linux-3.17.1]# /root/prep_arm_image_on_b3.sh
```

If this completes successfully, once you restart your B3, you'll be using your new kernel! (A backup of the prior kernel is also kept in the first partition, so you can roll back easily, using a rescue system, should anything go awry.)


## Keeping Your Arch Linux System Up-To-Date

You can update your system at any time (whether you are running Arch Linux from USB or the B3's internal drive). 

For more information, please refer to the official [pacman guide](https://wiki.archlinux.org/index.php/Pacman) (`pacman` is Arch Linux's package manager). However, here are some very brief hints to get you started.

To bring your package metadata up-to-date (similar to `apt-get update` in Debian), issue:
```
[root@archb3 ~]# pacman -Sy
   (confirm if prompted)
```

To install / upgrade a particular package (such as e.g., the apache web server), you can issue (equivalent to `apt-get upgrade ...` on Debian):
```
[root@archb3 ~]# pacman -S apache
   (confirm when prompted)
```

To bring the system completely up to date at any time (Arch Linux is a rolling distribution), issue:
```
[root@archb3 ~]# pacman -Syu
   (this will take some time to complete; confirm when prompted)
```
> Note that since you are using a custom kernel, per [this post](https://www.digitalocean.com/community/tutorials/pacman-syu-kernel-update-solved-how-to-ignore-arch-kernel-upgrades) you may wish to add `IgnorePkg=linux` to `/etc/pacman.conf`, in order to omit the kernel from upgrade (however, the way I have set things up, your current kernel should *not* be overwritten in any event, and due to the '-b3' suffix used, nor should your modules, so this step is optional - it just saves you a little disk space).

For more information about Arch Linux setup, see the official [Beginners' Guide](https://wiki.archlinux.org/index.php/beginners'_guide). Useful notes about system maintenance on Arch Linux are also available [here](https://wiki.archlinux.org/index.php/System_maintenance).

## Feedback Welcome!

If you have any problems, questions or comments regarding this project, feel free to drop me a line! (sakaki@deciban.com)
