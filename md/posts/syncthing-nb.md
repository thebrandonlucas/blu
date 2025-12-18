---
title: Open Source File Synchronization Across All Your Devices with Syncthing
description: How to synchronize files across many devices automagically
date: 2025-02-01
---

I use the [TUI](https://en.wikipedia.org/wiki/Text-based_user_interface)-based tool [nb](https://github.com/xwmx/nb) for writing things. But I have a few problems:
  1) I use it on a lot of different computers and often want to add to notes that only exist on computer A while I'm on computer B.
  2) Since everything I write on my website is in Markdown, I want to have the ability to have what I place in that notebook automatically update the website (or at least update it after a )

Solving Problem 1 will be the focus in this article. In a subsequent article, I plan to detail solving problem 2.

## Requirements

I want a system that _automatically_ syncs files across devices that have it installed on and connected to at an interval I define when the machine comes online.

## Syncthing 

After prompting [Perplexity.ai](https://www.perplexity.ai/) about the issue, two methods which appealed to me are [Syncthing](https://syncthing.net/) and Git. Using Git would've been more manual and time-consuming, and since Syncthing is a very popular tool and fully open source, I went with that option.

## Installing

Syncthing has a great ["Getting Started"](https://docs.syncthing.net/intro/getting-started.html) page that gave me everything I needed to know to use it. Just download the app on two devices. Select the architecture you're using from their releases page [here](https://github.com/syncthing/syncthing/releases). Follow their Getting Started page and you should have all the basics to get up and running.

## Helpful Notes

### Use Cases

Syncthing is not really meant to be a backup software like [rsync](https://linux.die.net/man/1/rsync), because changes made on one machine will synchronize to the other machines, and therefore if one machine deletes a file it will also be deleted on the other machine. It's meant to be a _sharing_ software keep documents on different computers synchronized, as the name suggests. Which means that it should really be used for things like media libraries or as an alternative to cloud storage solutions like Box or Google Drive, or when needing to edit documents on multiple machines, as in my case with `nb`.

### Mobile Devices

I wanted one of my devices to be my phone, so just note that for mobile (i.e. by mobile I mean _Android_ or a security-hardened derivative like [GrapheneOS](https://grapheneos.org/) — sorry iPhone fans, but their anti open source ethos precludes you from using this one) you have to use a [fork](https://github.com/Catfriend1/syncthing-android) of their [now deprecated Android app](https://github.com/syncthing/syncthing-android). You can download the apk file [here](https://github.com/Catfriend1/syncthing-android/releases).

### Folder Types

There are [three types](https://docs.syncthing.net/users/foldertypes.html) of folders:
- Send Only 
- Receive Only 
- Send and Receive

This is useful for sharing files while still setting some basic permissions for them. Send Only is great for sharing with people/devices that you don't want to be able to modify your local copy via their modifications; Receive Only is the opposite — it can only _be shared with_, and yet changes from the sending folder will not modify changes in the receiving folder.

### The FAQ is Very Helpful

Initially when using Syncthing I was confused about a few things (Should I use this for backups? Why does syncing take so long? How does it work? Will it ever connect to anything other than my own machines and can they see my data?). The [FAQ](https://docs.syncthing.net/users/faq.html#what-is-syncthing) answered all my questions very nicely and in detail, so be sure to give that a read.

### Note For Obsidian Users 

[Obsidian]() is an (unfortunately closed-source) note-taking app that pairs nicely with `nb`. I use `nb` on all my desk/laptop machines and use Obsidian on mobile since trying to use a terminal on mobile would be a terrible experience. After installing Syncthing-Fork on your mobile device and syncing the relevant folder, you can open that folder as your Vault in Obsidian. Before making any changes in Obsidian, however, you should disable a setting in Syncthing. Click on the synced folder, scroll down to "Watch for changes", and disable it. This will make it so changes to that synced directory will only attempt to sync changes to the others on an hourly basis. Obsidian saves files to disk extremely frequently, basically on every keystroke, and this caused Syncthing to behave strangely or simply not sync any changes made from Obsidian to the other devices. This is a bit unfortunate because there's a possibility that you could update the same file on your mobile device and another machine within that hour, causing a conflict. But fortunately Syncthing will save both versions of the file in a "conflict" file and you will have both versions so that there's no content loss.
