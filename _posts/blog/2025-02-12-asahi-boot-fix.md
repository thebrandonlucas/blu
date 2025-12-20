---
title: Hard Reset Asahi Linux After Boot Error and Data Backup
description: dnf update may cause a boot into a black screen. Here's how you can reset your computer.
date: 2025-02-12
tags: linux software
---

[Asahi Linux](https://asahilinux.org/) is a port of Linux on Apple Silicon (the M-series chips).

I've been using it fairly happily for awhile, but it booted into a black screen recently. I had a flash drive plugged in and I had also installed new programs using `dnf` (The Fedora package manager, which is the distro Asahi uses), and after some reddit searching it appears that the problem was caused by something having to do with `dnf update`. After restarting the computer, it showed the Apple logo, Asahi logo, and Fedora logo in sequence as usual, and then never booted past a black screen. Unfortunately I wasn't really able to "fix" it, but I was at least able to get into a terminal screen, mount a flash drive, backup my data, and then do a hard reset.

On boot, press and hold FN + CTRL + OPTION + F2. This should take you into a terminal-based login screen. Login with your normal user credentials. Then plugin a flash drive. Identify the device name by typing `lsblk`. It should appear as `/dev/sda` or something of the like. You should be able to identify it by its' file size (e.g. 32GB, etc.). Then, mount the device. First, you should create a mount point using `mkdir`, such as in `/mnt`:

Create a mount point:

```
sudo mkdir `/mnt/mydrive`
```

Mount the device:

```
sudo mount /dev/sda /mnt/mydrive
```

Copy files from your `home` directory (or wherever you have data stored you want to keep) to the flashdrive:

```
cp -r ~/* /mnt/mydrive
```

Unmount and eject the drive when done:

```
sudo umount /mnt/mydrive
sudo eject /dev/sda
```

### Repartition the Hard Drive

Now, you'll need to do a complete uninstall/reinstall of Asahi Linux by repartitioning the hard drive on your Mac.

I followed [this tutorial video](https://www.youtube.com/watch?v=nMnWTq2H-N0&t=7s) to help me repartition the Mac properly, and it worked like a charm. Then, I was able to go through the same process of reinstalling Asahi again and using my Apple Silicon machine with Linux.
