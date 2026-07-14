---
title: "Kai: A Friendly Frontend for Determinate Computing"
description: Making determinate computing friendly by building a modular frontend for Nix, Guix, and future reproducible systems.
date: 2026-07-13
tags: nix software open-source
---

> Simple things should be simple, complex things should be possible.
>
> - [Alan Kay](https://www.quora.com/What-is-the-story-behind-Alan-Kay-s-adage-Simple-things-should-be-simple-complex-things-should-be-possible)

[`nix`](https://docs.determinate.systems/determinate-nix), and the whole ecosystem surrounding it, is the only major attempt at a top-to-bottom solution to the problem of reproducible software. There is one other that has implemented this ([guix](https://guix.gnu.org/)), but its mindshare is dwarfed by Nix's, which is in turn dwarfed by other package managers and Linux distros, which are in turn dwarfed by proprietary programs and operating systems like macOS and Windows.

Nix is, most fundamentally, a means of getting software from machine or environment A to machine or environment B in a deterministic way: that is, as long as you can use `nix` on both machines to perform the transfer and the target machine has the resources to run the program, you can guarantee that the software will be transferred completely and have all the dependencies it needs to run. No other major package manager does this.

Technically this is a big leap forward, but, given how few use `nix`, we can't yet call it that. It's no secret that [`nix`](https://docs.determinate.systems/determinate-nix) is [notoriously difficult](https://bmcgee.ie/posts/2023/01/nix-and-nixos-a-retrospective/) to use. But it seems to me that many of these problems are problems of [accidental complexity](https://en.wikipedia.org/wiki/No_Silver_Bullet#Accidental_complexity) (problems engineers create through suboptimal design and can therefore fix) rather than [essential complexity](https://en.wikipedia.org/wiki/No_Silver_Bullet#Essential_complexity) (problems inherent to the problem itself). Since Nix is very old (older than `git`!), there has been a lot of churn on tooling, which has resulted in a _lot_ of tooling, a [monolithic architecture](https://tvl.fyi/blog/rewriting-nix), [split](https://nixos.org/community/) [communities](https://determinate.systems/), [outdated documentation](https://discourse.nixos.org/t/nixpkgs-manual-out-of-date/8500), and [many](https://nickel-lang.org/) [many](https://devenv.sh/) [many](https://www.jetify.com/devbox) third party solutions aiming to solve (and re-solve) the same accidents of complexity.

`nix` does not do [one thing well](https://cscie2x.dce.harvard.edu/hw/ch01s06.html) nor is there [one obvious way to do any given thing](https://ziglang.org/download/0.1.1/release-notes.html): [simple things are complex and complex things are complex](https://www.quora.com/What-is-the-story-behind-Alan-Kay-s-adage-Simple-things-should-be-simple-complex-things-should-be-possible).

That said, at its base, `nix` is a beautiful idea, and an elegant solution to the software distribution problem. It enables so many positive downstream effects. It makes your *package management and operating system declarative*, and brings the deterministic, mathematical certainty of a functional language to your computer-using experience. *That* is power.

Thus, we have a revolutionary tool that basically no one uses because it is very difficult and the ecosystem is fragmented. Therefore I believe that the consequences of making a determinate system like `nix` easy to use will have a profound impact on how we interact with computers for the better.

As such, this problem is begging for a solution.

## Kai - A Friendly Frontend for Determinate Computing

I've begun working on one such solution which I'm calling [`kai`](https://github.com/thebrandonlucas/kai), short for the [Ancient Greek καιρός](https://en.wikipedia.org/wiki/Kairos) or "the right time". At first glance, it is just lipstick on `nix`, which alone would be great. But with the proper design we can architect it to be much more.

The goal is to:

1. Define a generic protocol which enumerates a set of capabilities any determinate system should have, such as:
    - Reproducible developer shells for teams and projects (probably the most common `nix` use case now)
    - Ad-hoc shells for testing out software on the fly
    - Build targets allowing you to create virtual machines, or deployments with the specified software and configurations preinstalled, or the ability to create custom ISOs to roll your own operating system configuration!
    - Rollback to previous generations if a new dependency breaks the system
    - Automated garbage collection for dangling dependencies no longer in use
    - etc.
2. Implement the protocol in a CLI tool and config file such that it is compatible with the two full-fledged determinate systems (`nix` and `guix`) and any others which later implement the generic protocol, eliminating as much accidental complexity as possible and making them *friendly* and *fun* to use. The mappings of the generic protocol to the concrete implementations we call [blueprints](https://github.com/lukewilliamboswell/roc-blueprint) (thanks [Luke Boswell](https://github.com/lukewilliamboswell)!)
3. Make the tool modular such that users can:
    - Take only those parts of the determinate system which they want (some may only be interested in reproducible shells while others want build systems -- there should of course be a "default" option which has everything the average user wants).
    - Modify or create their own implementation of a given tool. For example, [tvix](https://tvl.fyi/blog/rewriting-nix) spawned out of a desire to make a *modular* `nix` implementation since the primary implementation is *monolithic*, the problem being that if you don't like the way a given piece works or believe it is inefficient, you cannot easily swap it out for a different implementation and must satisfy yourself with the monolith.
    - Add new modules and commands as desired (for example one may want a `kai deploy` which handles deploying to their VPS of choice).

This clearly goes beyond "make a better `nix` frontend". The motivation is that this design will allow us to experiment and play with designs for a _better_ system while being backward compatible with existing ones. And further, replace *components* of one of the existing systems (e.g. replacing one of the `nix` components with a `tvix` one, but still having the total package management solution be `nix`-compatible).

It is built in the [`roc`](https://www.roc-lang.org/) programming language, a high-level functional language which allows us to create platforms (in a lower-level language, `zig`, in this case) which define behavior tailored to specific use-cases. For example, in our case we create a platform to specify an EDSL ([Embedded Domain-Specific Language](https://learn-haskell.blog/03-html/03-edsls.html)) to implement the determinate protocol.

So far, `kai` is just a proof of concept which implements a basic version of each of the three ideas above. The nascent determinate protocol so far has two commands in the CLI, `shell` and `build`:

- `shell`: Enters a shell containing the packages specified in `kai.roc` by calling the corresponding `shell` command. This is equivalent to a `flake.nix` for `nix` and a `manifest.scm` for `guix`. If none exists in the current directory, it scaffolds a `kai.roc` file with no packages. Example:

    ```roc
    app [config] { kai: platform "../platform/config.roc" }

    config = [
        Shell({
            name: "simple-kai-shell",
            # `packages` is a Roc header keyword in this compiler, so shell configs use `pkgs`.
            pkgs: ["git"],
        }),
    ]
    ```

- `build`: Builds the specified machine image according to `kai.roc`. Technically this should be a generic build for any target, but I've chosen a very common use case for the time being for simplicity. Example:

    ```roc
    app [config] { kai: platform "../platform/config.roc" }

    config = [
        MachineBuild({
            hostname: "kai-example",
            system: "x86_64-linux",
            install: ["git"],
            ssh_keys: [],
            state_version: "25.05",
            image: { format: "qcow2" },
        }),
    ]
    ```

There is also a third command, `blueprint`, which allows you to choose the backend which implements the determinate protocol. In our case we have two blueprints which can implement `shell` and `build`: `nix` and `guix`. So if you `blueprint list` to see your options, then do `blueprint set nix`, calling `shell` will perform `nix develop` under the hood and `build` will call the appropriate command to build the machine above.

There is also a `.kai` directory which manages a config file corresponding to the blueprint. For `nix`, `.kai` will contain a `flake.nix` and our `build` and `shell` commands will manipulate and use that under the hood. For `guix`, the file is `manifest.scm`.

Next in the plan is to add a bespoke `deploy` command modularly, such that `deploy` can mean different things for different people, and we can both (1) show the power of `kai` to easily deploy machines preconfigured with software, and (2) show how people can extend `kai` commands to suit their various use cases.

Onward!
