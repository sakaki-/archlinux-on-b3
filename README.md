# archlinux-on-b3

Bootable live-USB of Arch Linux for the Excito B3 miniserver (with [archlinuxarm.org](http://archlinuxarm.org) kernel!)

<img src="https://raw.githubusercontent.com/sakaki-/resources/master/excito/b3/Excito_b3.jpg" alt="Excito B3" width="250px" align="right"/>
This project contains a bootable, live-USB image for the Excito B3 miniserver. You can use it as a rescue disk, to play with Arch Linux, or as the starting point to install Arch Linux on your B3's main hard drive. You can even use it on a diskless B3. No soldering, compilation, or [U-Boot](http://www.denx.de/wiki/U-Boot/WebHome) flashing is required! You can run it without harming your B3's existing software; however, any changes you make while running the system *will* be saved to the USB (i.e., there is persistence).

As of release 1.1.0, the current [linux-kirkwood-dt](https://github.com/archlinuxarm/PKGBUILDs/tree/master/core/linux-kirkwood-dt) kernel from [archlinuxarm.org](http://archlinuxarm.org) is used. Accordingly, this will automatically be updated (along with all other packages on your system) whenever you issue `pacman -Syu`.
> For those interested, this is possible (_without_ requiring a U-Boot reflash) because the image actually boots an interstitial kernel to begin with. This first kernel (whose version never changes) runs a [script](https://github.com/sakaki-/archlinux-on-b3/blob/master/reference/initramfs-init-on-b3) from its integral initramfs to patch the 'real' archlinuxarm kernel in `/boot`, set up the command line, load the patched kernel into memory, and then switch to it (using `kexec`). The sourced script fragment `/boot/kexec.sh` (which you can see [here](https://github.com/sakaki-/archlinux-on-b3/blob/master/reference/kexec-on-live-usb.sh)) carries the majority of this work, and you can edit this file if you like (for example, to modify the kernel command line).

The image may be downloaded from the link below (or via `wget`, per the following instructions).
> Note that if you wish to use this image in a 'diskless' chassis, you will need to make a few small changes before booting, which are detailed later in these notes.

Variant | Version | Image | Digital Signature
:--- | ---: | ---: | ---:
B3 with or without Internal Drive | 1.1.3 | [archb3img.xz](https://github.com/sakaki-/archlinux-on-b3/releases/download/1.1.3/archb3img.xz) | [archb3img.xz.asc](https://github.com/sakaki-/archlinux-on-b3/releases/download/1.1.3/archb3img.xz.asc)

The older images are still available [here](https://github.com/sakaki-/archlinux-on-b3/releases).

> Please read the instructions below before proceeding. Also please note that the image is provided 'as is' and without warranty. And also, since it is largely based on the Kirkwood image from [archlinuxarm.org](http://archlinuxarm.org) (fully updated as of 29 March 2015), please refer to that site for licensing details of firmware files etc.

## Prerequisites

To try this out, you will need:
* A USB key of at least 4GB capacity (the _compressed_ (.xz) image is 144MiB, the uncompressed image is 7,358,464 (512 byte) sectors = 3,767,533,568 bytes). Unfortunately, not all USB keys work with the version of [U-Boot](http://www.denx.de/wiki/U-Boot/WebHome) on the B3 (2010.06 on my device). Most SanDisk and Lexar USB keys appear to work reliably, but others (e.g., Verbatim keys) will not boot properly. (You may find the list of known-good USB keys [in this post](http://forum.doozan.com/read.php?2,1915,page=1) useful.)
* An Excito B3 (obviously!). As shipped, the image assumes you have an internal hard drive fitted; if using a diskless chassis, be sure to follow the instructions given later, before attempting to boot.
* A PC to decompress the appropriate image and write it to the USB key (of course, you can also use your B3 for this, assuming it is currently running the standard Excito / Debian Squeeze system). This is most easily done on a Linux machine of some sort, but tools are also available for Windows (see [here](http://tukaani.org/xz/) and [here](http://sourceforge.net/projects/win32diskimager/), for example). In the instructions below I'm going to assume you're using Linux.

## Downloading and Writing the Image

On your Linux box, issue:
```
# wget -c https://github.com/sakaki-/archlinux-on-b3/releases/download/1.1.3/archb3img.xz
# wget -c https://github.com/sakaki-/archlinux-on-b3/releases/download/1.1.3/archb3img.xz.asc
```
to fetch the compressed disk image file (144MiB) and its signature.

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
> Users of standard B3s (which have an internal hard drive, running, for example, the normal Excito system), can (and should) skip this step - the shipped image already has the correct kernel (and `fstab`) in place for you. Continue reading at "Booting!", [below](#booting).

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
# sed -i s/sdb/sda/g /tmp/mntusb/kexec.sh
# sync
# umount -v /tmp/mntusb
# mount -v /dev/sdX3 /tmp/mntusb
# sed -i s/sdb/sda/g /tmp/mntusb/etc/fstab
# sync
# umount -v /tmp/mntusb
# rmdir /tmp/mntusb
```

Obviously, substitute the appropriate path for `/dev/sdX1` and `/dev/sdX3` in the above. If your USB key is currently on `/dev/sdc`, you'd use `/dev/sdc1` and `/dev/sdc3`; if it is on `/dev/sdd`, you'd use `/dev/sdd1` and `/dev/sdd3`, etc.

## <a name="booting"></a>Booting!

All done, you are now ready to try booting your B3!

Begin with your B3 powered off and the power cable removed. Insert the USB key into either of the USB slots on the back of the B3, and make sure the other USB slot is unoccupied. Connect the B3 to your local network using the **wan** Ethernet port. Then, *while holding down the button on the back of the B3*, apply power (insert the power cable). After five seconds or so, release the button. If all is well, the B3 should boot the interstitial kernel off of the USB key (rather than the internal drive), then patch, load and `kexec` the archlinuxarm.org kernel, and then proceed to mount the root partition (also from the USB key) and start Arch Linux. This will all take about 60 seconds or so. The LED on the front of the B3 should:

1. first, turn **green**, for about 20 seconds, as the interstitial kernel loads; then,
1. turn **off** for about 10 seconds, and the 'real' kernel is patched and loaded; then
1. turn **purple** for about 20 seconds, as the real kernel boots, and then
1. turn **green** as Arch Linux comes up.

About 20 seconds after the LED turns green in step 4, above, you should be able to log in, via ssh, per the following instructions.

> The image uses a solid green LED as its 'normal' state, so that you can easily tell at a glance whether your B3 is running an Excito/Debian system (blue LED) or a Arch Linux one (green LED).

> Also, please note that if you have installed Arch Linux to your internal HDD (per the instructions given [later](#hdd_install)), and are booting from the HDD, that the front LED will be **purple**, not green, during phase 1.

## Connecting to the B3

Once booted, you can log into the B3 from any other machine on your subnet (the root password is **root**). Issue:
```
$ ssh root@192.168.1.129
The authenticity of host '192.168.1.129 (192.168.1.129)' can't be established.
ED25519 key fingerprint is 30:04:59:a6:cf:e6:bb:c2:ea:53:53:b3:2a:fa:88:d2.
Are you sure you want to continue connecting (yes/no)? <type yes and press Enter>
Warning: Permanently added '192.168.1.129' (ED25519) to the list of known hosts.
root@192.168.1.129's password: <type root and press Enter>
[root@archb3 ~]# 
```
and you're in!  (If you get `connection refused`, simply wait a few seconds longer, then try again.) Obviously, substitute the correct network address for your B3 in the command above (if you changed it in `/install/wan`, earlier). Note that you may receive a different fingerprint type, depending on what your `ssh` client supports. Also, please note that as of version 1.1.0, the `ssh` host keys are generated on first boot (for security), and so the fingerprint you get will be different from that shown above.

> **Important:** if you have changed the settings in `/install/wan`, and are unable to log in the first time (even though your B3 appears to have booted OK), try powering off your B3 (hold down the rear button for about 5 seconds, and wait for the front LED to turn off). Then, boot from the USB (with the rear button held down) one further time. You should find that your changed settings have now been accepted, and you can `ssh` in successfully. (Incidentally, the race condition that caused this issue has been addressed as of release 1.1.1.)

If you have previously connected to a *different* machine with the *same* IP address as your B3 via `ssh` from the client PC, you may need to delete its host fingerprint (from `~/.ssh/known_hosts` on the PC) before `ssh` will allow you to connect.

## Using Arch Linux

The supplied image contains a configured Arch Linux system, based on the `ArchLinuxARM-kirkwood-latest.tar.gz` image from the [archlinuxarm.org repo](http://archlinuxarm.org/os/), so you can immediately perform `pacman` operations (Arch Linux's equivalent of `apt-get`) etc. See the section ["Keeping Your Arch Linux System Up-To-Date"](#updating) near the end of this document.

Be aware that, as shipped, it has a UTC timezone and no system locale; however, these are easily changed if desired. See the [Arch Linux Beginners' Guide](https://wiki.archlinux.org/index.php/beginners'_guide) for details.

The drivers for WiFi (if you have the hardware on your B3) *are* present, but configuration of WiFi in master mode (using hostapd) is beyond the scope of this short write up (see [here](http://nims11.wordpress.com/2012/04/27/hostapd-the-linux-way-to-create-virtual-wifi-access-point/) for some details). The wifi interface name is `wlp1s0`, and the wireless regulatory domain (`/etc/conf.d/wireless-regdom`) is currently set to `GB`.
> You can use the `iwconfig` command to show the status of your wireless adaptors.

Similarly, the **lan** port can be accessed via `eth1`, but is not currently set to come up on boot. You can modify the behaviour as you like using the `netctl` utility (`eth1`'s default controlling profile is called `lan` on the image); see [these notes](https://wiki.archlinux.org/index.php/netctl) for example. There is also some useful information about `netctl`, bridging etc. on [this wiki page](http://wiki.mybubba.org/wiki/index.php?title=Running_Arch_Linux#The_netctl_way).

> Please be aware that, because the image uses `kexec` to boot the [archlinuxarm.org](http://archlinuxarm.org) kernel, the MACs of the ethernet adaptors (eth0 and eth1) are _not_ set by U-Boot, but by the `setethermac` service (see the file `/etc/systemd/system/setethermac@.service`). Accordingly, if you use a udev rule to change the names of these interfaces (as suggested [here](http://wiki.mybubba.org/wiki/index.php?title=Running_Arch_Linux#Prepare_Network_Interfaces), for example), their MACs will not be correctly initialized, and you may be unable to connect.

> Similarly, if you define a `netctl` profile which references either `eth0` or `eth1` (and which is not called `wan` or `lan`), then please add that profile to the `Before=` dependency line in the `/etc/systemd/system/setethermac@.service` file.

Once you have networking set up as you like it, you should issue:
```
[root@archb3 ~]# systemctl disable copynetsetup 
```
to prevent your `wan` settings being overwritten again by the file in the first USB partition, next time you boot.

When you are done using your Arch Linux system, you can simply issue:
```
[root@archb3 ~]# systemctl reboot
```
and your machine will cleanly restart back into your existing (Excito) system off the hard drive. At this point, you can remove the USB key if you like. You can then, at any later time, simply repeat the 'power up with USB key inserted and button pressed' process to come back into Arch Linux - any changes you made will still be present on the USB key.

To power off cleanly (rather than rebooting), you have two options. First, as the image now includes Tor's [bubba-buttond](https://github.com/Excito/bubba-buttond) (built statically), you can simply press the B3's rear button for around 5 seconds, then release it (just as you would on a regular Excito system). The front LED will turn from green to purple, then turn off once it is safe to physically remove the power cable.

Second, if you'd rather use the command line, you can issue:
```
[root@archb3 ~]# poweroff-b3
```
which will have the same effect (and follow the same power-down LED sequence).

Have fun! ^-^

## Miscellaneous Points

* The specific B3 devices (LEDs, buzzer, rear button etc.) are now described by the file `arch/arm/boot/dts/kirkwood-b3.dts` in the main kernel source directory (and included in the git archive too, for reference). You can see an example of using the defined devices in `/etc/systemd/system/bootled.service`, which turns on the green LED as Arch Linux starts up, and off again on shutdown (this replaces the previous [approach](http://wiki.mybubba.org/wiki/index.php?title=Let_your_B3_beep_and_change_the_LED_color), which required an Excito-patched kernel).
* The live USB works because the B3's firmware boot loader will automatically try to run a file called `/install/install.itb` from the first partition of the USB drive when the system is powered up with the rear button depressed. In the provided image, we have placed a bootable (interstitial) kernel uImage in that location. Despite the name, no 'installation' takes place, of course!
* If you have a USB key larger than the minimum 4GB, after writing the image you can easily extend the size of the second partition (using `fdisk` and `resize2fs`), so you have more space to work in. See [these instructions](http://geekpeek.net/resize-filesystem-fdisk-resize2fs/), for example.

## <a name="hdd_install">Installing Arch Linux on your B3's Internal Drive (Optional)

If you like Arch Linux, and want to set it up permanently on the B3's internal hard drive, you can do so easily (it takes less than 5 minutes). The full process is described below. (Note, this is strictly optional, you can simply run Arch Linux from the USB key, if you are just experimenting, or using it as a rescue system.)

> **Warning** - the below process will wipe all existing software and data from your internal drive, so be sure to back that up first, before proceeding. It will set up:
* /dev/sda1 as a 64MiB boot partition, and format it `ext3`;
* /dev/sda2 as a 1GiB swap partition;
* /dev/sda3 as a root partition using the rest of the drive, and format it `ext4`.

> Note also that the script `/root/install_on_sda.sh` will install using a DOS partition table (max 2TiB); if you'd rather use GPT, then use `/root/install_on_sda_gpt.sh` instead. [All B3s](http://forum.mybubba.org/viewtopic.php?f=7&t=5755) can boot from a GPT-partitioned drive; however, please note that if your HDD has a capacity > 2TiB, then only those B3s with a [relatively modern](http://forum.mybubba.org/viewtopic.php?f=9&t=5745) U-Boot will work correctly. The DOS partition table version should work for any size drive (but will be constrained to a maximum of 2TiB).

OK, first, boot into the image and then connect to your B3 via `ssh`, as described above. Then, (as of version 1.1.0) you can simply run the supplied script to install onto your hard drive:
```
[root@archb3 ~]# /root/install_on_sda.sh
Install ArchLinux -> /dev/sda (B3's internal HDD)

WARNING - will delete anything currently on HDD
(including any existing Excito Debian system)
Please make sure you have adequate backups before proceeding

Type (upper case) INSTALL and press Enter to continue
Any other entry quits without installing: <type INSTALL and press Enter, to proceed>
Installing: check '/var/log/arch_install.log' in case of errors
Step 1 of 5: creating partition table on /dev/sda...
Step 2 of 5: formatting partitions on /dev/sda...
Step 3 of 5: mounting boot and root partitions from /dev/sda...
Step 4 of 5: copying system and bootfiles (please be patient)...
Step 5 of 5: syncing filesystems and unmounting...
All done! You can reboot into your new system now.
```

That's it! You can now try rebooting your new system (it will have the same initial network settings as the USB version, since we've just copied them over). Issue:
```
[root@archb3 ~]# systemctl reboot
```
And let the system shut down and come back up. **Don't** press the B3's back-panel button this time. The system should boot directly off the hard drive. You can now remove the USB key, if you like, as it's no longer needed. Wait 40 seconds or so, then from your PC on the same subnet issue:
```
$ ssh root@192.168.1.129
root@192.168.1.129's password: <type root and press Enter>
[root@archb3 ~]# 
```
Of course, use whatever IP address you assigned earlier, rather than `192.168.1.129` in the above. Also, if you changed root's password in the USB image, use that new password rather than `root` in the above.

Once logged in, feel free to configure your system as you like! Of course, if you're intending to use the B3 as an externally visible server,  you should take the usual precautions, such as changing root's password, configuring a firewall, possibly [changing the `ssh` host keys](https://missingm.co/2013/07/identical-droplets-in-the-digitalocean-regenerate-your-ubuntu-ssh-host-keys-now/#how-to-generate-new-host-keys-on-an-existing-server), etc.

## <a name="updating"></a>Keeping Your Arch Linux System Up-To-Date

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
You can install any packages you like using `pacman`, it should not break your system (you can search for available packages [here](http://archlinuxarm.org/packages), filter by `armv5` architecture). If working from the USB, any packages you install will still be present next time you boot off the USB (and will also be copied over to the hard drive, should you choose to do that, as described earlier).

To bring the system completely up to date at any time (Arch Linux is a rolling distribution, so it is [recommended](https://wiki.archlinux.org/index.php/pacman#Partial_upgrades_are_unsupported) to do this prior to installing any new packages), issue:
```
[root@archb3 ~]# pacman -Syu
   (this will take some time to complete; confirm when prompted)
```

Note that this may also upgrade your kernel, if a new version has become available on [archlinuxarm.org](http://archlinuxarm.org). In this case, you may see a warning like the following printed out during the upgrade:
```
(n/m) upgrading linux-kirkwood-dt                  [#####################] 100%
>>> Updating module dependencies. Please wait ...
    Remember, on most systems this new kernel will not boot without
    further user action.
```

However, you do not need to worry, as the interstitial kernel's `init` will take care of this "further user action" for you. Simply reboot, and you'll be using your new kernel!

For more information about Arch Linux setup, see the official [Beginners' Guide](https://wiki.archlinux.org/index.php/beginners'_guide). Useful notes about system maintenance on Arch Linux are also available [here](https://wiki.archlinux.org/index.php/System_maintenance).

## Feedback Welcome!

If you have any problems, questions or comments regarding this project, feel free to drop me a line! (sakaki@deciban.com)
