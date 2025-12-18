---
title: February 2025
description: Journal
---

_2025-02-20_

- _Thought_: Perhaps the next browser just be an LLM that cites it's sources. That's it. I literally just open the browser and see a chatbox, can switch between LLM backends, and can use my own locally-hosted one if I'd like. For the ones I can't buy, I just pay a bitcoin lightning invoice to use. That's it!

- _Thought_: I wonder how much it would be to build a desktop computer that could run Deepseek 1776? Much cheaper than buying a laptop with equivalent specs, I suppose?

- It would be cool to do an aggregate of the most popular tools rated by experts in each domain in software is. I.e. frontend developers love [Svelte](https://svelte.dev/), backend developers love [Rust](https://www.rust-lang.org/), SysAdmins love, I dunno, [tmux?](https://github.com/tmux/tmux/wiki), etc. There should be some criteria that we develop for what makes software "high-ranking", such as it's survival rate ("vim" and "emacs" are both still around and extremely popular, so they get high scores). Similar to the way in economics we have the measure the quality of a currency by its fungibility, divisibility, portability, durability, scarcity.

- _accountless.io or Awesome Accountless_: Maintain a repo/website of services which do not require accounts/respect privacy/are free and open source etc., for their use.

- Today I ran and connected to a Minecraft server self hosting on my local NixOS device running over a Wireguard VPN. The server exists in the `minecraft-server` package, but you have to first do two things in your /etc/nixos/configuration.nix file:
  - Add the lines:
    ```nix
    nixpkgs.config = {
      allowedUnfree = ["minecraft-server"]
    }
    ```
    By default, NixOS does not include Free and Open-Source Software (FOSS). So for any package that you try to download that doesn't isn't FOSS (which includes Minecraft 🥲), you'll get this error. You can explicitly define which packages you'd like to have as unfree in an array as done above, or you can just generically do `nixpkgs.config.allowUnfree = true;`. I opted for specificity as I want to include as little unfree software as possible ;)
  - The second issue, which I got tripped up on for awhile, was the firewall. NixOS has configuration options for letting certain ports past the firewall. The `minecraft-server` port is 25565 (which you can see if you observe the server logs), so we want to allow packets through both (I believe both are necessary, anyway) the UDP and TCP port `25565`, like so:
    ```nix 
    nixpkgs.firewall.allowedTCPPorts = [ 25565 ];
    nixpkgs.firewall.allowedUDPPorts = [ 25565 ];
    ```

    After that's done, remember to run `sudo nixos-rebuild switch` to rebuild your NixOS configuration, and you should now be able to connect, assuming that server is reachable via your computer.

- I also managed to get Nextcloud running on my NixOS server, using [this guide](https://nixos.wiki/wiki/Nextcloud
) and some help from [ppq.ai](https://ppq.ai) (Grok 2, in this case). Here is the setup I used:
```nix
  environment.etc."nextcloud-admin-pass".text = "PWD";
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud30;
    hostName = "10.8.0.2"; # An example of an IP assigned to the device by Wireguard VPN. This way it's accessible from other devices.
    config.adminpassFile = "/etc/nextcloud-admin-pass";
    config.dbtype = "sqlite";
  };
  ```

  There are a couple of deviations here from the original post. First, I needed to upgrade to pkgs.nextcloud30 instead of pkgs.nextcloud28, as the docs recommend (it's officially deprecated and `nixos-rebuild switch` will hassle you about it). You also have to change `"PWD"` to a password that's allowed by [Nextcloud's default password policy](https://docs.nextcloud.com/server/latest/admin_manual/configuration_user/user_password_policy.html) as mentioned in the article above, which, in my case, just amounted to creating a secure password with a password manager and them using that.

  Also, be sure to later enable the TCP ports 80 (HTTP) and 443 (HTTPs):
  ```nix 
  nixpkgs.firewall.allowedTCPPorts = [ 80 443 ];
  ```

  I was able to access the Nextcloud UI at `10.8.0.2` after this! However, I got stuck in password hell for reasons I cannot fathom (it _seemed_ like it was loading my password correctly, only to tell me after over 10 seconds that the password was wrong). What I _think_ was happening was that Nextcloud wasn't accepting the original password I used, which was something stupid simple like `password123`, and it was failing Nextcloud's password rules. But then when I went to change it, something about the database was already screwed up or my IP address was just banned and I couldn't login even after having set a good password. In the end, I just ended up nuking all the Nextcloud setup via `sudo rm -rf /var/lib/nextcloud` (careful with that command!), and then I re-ran `sudo nixos-rebuild switch` which re-setup the config with a good password from the start this time. And wouldn't you know it, things worked! I could login with the default username of `root` and the password I had set in the config above.

By the way, another neat trick I learned is that you can look up what options exist for a `nix` service by using the `nixos-option` command. By running `nixos-option services.nextcloud.config`, I found you could set an admin username of your choice as well via `config.adminuser`.

---

_2025-02-18_

- I now have:
  - A VPS running Wireguard VPN which my devices are connected to
  - An Apple Silicon (Macbook M1) computer running NixOS 
  - The NixOS Macbook running a Jellyfin server for my media
  - The Jellyfin server can successfully be accessed by any computer connected to the VPN

- Example of why I love open-source. I was having an issue today where my Jellyfin server would keep disconnecting from my other devices, seemingly sporadically, after awhile. Often when checking the logs I would see an error related to websockets, but didn't understand why it was occurring. After browsing the [Jellyfin Github Issues](https://github.com/jellyfin/jellyfin/issues) for a bit [I discovered](https://github.com/jellyfin/jellyfin/issues/13379) someone who very likely is running into the same issue as me. It likely has something to do with running Jellyfin on Apple Silicon, which I am, despite the OS being NixOS. This person opened the issue last month, and the maintainers responded saying they had resolved it in the upcoming release. That release happened two days ago, and the maintainers responsible for pushing that update to the Nix package manager are now behind, so I literally can't update it yet. But because the project was open-source, I could find that I had the same problem as someone else, and rest assured that I simply have to update my software when the release becomes available. And since the Nix package for Jellyfin is only one patch version behind, I expect that to be very soon.

- _Idea_. [ppq.ai](https://ppq.ai) allows you to access many different AI models using micropayments. It's amazing. The only thing I'd like now is a command line tool that I can use their API with.

--- 

_2025-02-15_

- Thought - in general, we really need more things that are just "type these values into a list and run a program against it". NixOS's idea of just having a configuration file that defines an operating system is brilliant and is something we should have been doing for much longer in the computing world, and more programs and systems should operate this way. Instead of having to "re-setup" your computer every time you buy a new one (or relying on cleverly closed-source solutions like Apple has thus far successfully managed to do), you just plop in your config, sync your data, and _boom!_, you're back in business. Over the years your computer would become more and more personalized to _you_. As a side note, it seems this means NixOS can sort of be a playground with which to create the best operating systems (you can configure anything pre-built).

- *Idea* - Feedify - Turn a set of Markdown files into an RSS Feed. We really need to make RSS Great Again. It would appear, at a superficial glance, that it is just architecturally much more user friendly, privacy-respecting, and self-hostable in every way. Why don't we all use it? And, for what it's worth, XMPP for messaging?

- Thought - I got this idea from [Luke Smith](https://lukesmith.xyz/), but wouldn't it be awesome to have browsers that could be constructed from config files as well?


- *Installing NixOS on Apple Silicon*: (Note: I went ahead and *uninstalled* asahi linux to simplify the process, since these docs seem to assume a clean installl). I followed the instructions [here](https://github.com/tpwrules/nixos-apple-silicon/blob/main/docs/uefi-standalone.md), _carefully_, and was successfully able to run (headless, at least) NixOS on Apple Sillicon.

---

_2025-02-14 - Valentine's Day. ssh-copy-id_

This lovely Valentine's, I learned about a cool command for automating `ssh` logins to another computer.

`ssh-copy-id` sets up the `ssh` keypair exchange for you automatically by just running it against your `username@host-ip` like so:

```bash
ssh-copy-id root@123.456.789
```

Then, it'll ask you for your password, and voila! You should now have `ssh` setup between your computer and the host such that the next time you run `ssh root@123.456.789` it will just auto-log you in, no passwords required!

---


