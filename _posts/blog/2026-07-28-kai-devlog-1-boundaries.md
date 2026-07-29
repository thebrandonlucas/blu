---
title: "Kai Devlog #1: Boundaries"
description: Finding the right boundary between Kai's simple configuration and Nix's power.
date: 2026-07-28
tags: nix software open-source
layout: "Post"
---

I've released a tiny prototype of [Kai](https://github.com/thebrandonlucas/kai). It has one useful command: `kai shell`. It does one thing: reads the contents of a `kai.roc` file, creates a `.kai/flake.nix` in the current directory, then calls `nix` under the hood to put you into a shell with the programs defined in the flake.

A _lot_ of work went into doing that very basic thing that is a near-zero improvement over `nix` itself, because so much went into the underlying design that I'm hoping will make Kai a [_Zero to One_](https://www.ebay.com/itm/254467919121?_skw=zero+to+one&epid=167621430&itmmeta=01KYK8B5T2R1700BNT92NH7B4W&hash=item3b3f784d11:g:weYAAOSwbKJglu9o&itmprp=enc%3AAQALAAAA0GfYFPkwiKCW4ZNSs2u11xDO%2BTPzFgfgppO%2BGxK2WxXD0LFr--%2BcpcQnEL22eIxi0ffSConw%2FSboIzOyd8hE4smQE70cDmIK8G78BzAURQbg9eZcUC7ZAdsCaPYikvzMLwRoHkuNnEivxx6Og4KrJKzsRTdRybMhlykiTo%2FC5ecL7v6rwXk2dkkApAy4lKvoYaddnkmabN3VKGjnAcrr1nlRSUSKrG3B64JejIarC4lbFgsUHquCv8rfbgYxEiA99DDGpvcjXIz718Bj03aFQag%3D%7Ctkp%3ABk9SR6DdrOj0Zw) tool: an upgrade to the interface of deterministic computers so delectable and powerful that it will make the human experience, tooling interop, and agentic efficiency orders of magnitude better.

## Finding a Boundary

One of the main ideas behind Kai is for the user to manage a simple config file, `kai.roc`, which can serve as a simplified interface for interacting with your determinate system (for the vast majority, Nix under the hood). This is hard, because:

- A) Nix has so many layers of the stack, e.g.:
    - Nix the language, used by:
    - Nix the package manager, used by:
    - NixOS, along with:
    - The nixpkgs package repository

That's a *lot* of layers interoperating in a "closed" way because:

- B) Nix built these monolithically, such that it's [very hard](https://tvl.fyi/blog/rewriting-nix) to take one piece of that stack and use it for anything useful outside of the broader ecosystem. This means two things:
    - Boundaries are difficult to isolate at the conceptual level (essential complexity baked into the Nix ecosystem).
    - Boundaries are difficult to isolate at the code level (accidental complexity due to years upon years of cruft, ad-hoc development, and no real competition leading to a lack of need for interop).

All of this together forms a natural walled garden: unlike Apple, which *intentionally* fights its users by hiding code for the sake of (Apple believes) reduced complexity and financial incentives, Nix seems to have created one by accident. While explicitly encoding preferences for open software (via, for example, needing to manually modify configs to set a flag `allowUnfree = true`) and a philosophy which advocates maximal user control over their systems, in practice it is so complex and abstruse for the average daily user, with so many layers, that anyone who wishes to improve upon or isolate a single piece faces a very effective barrier to general adoption because, in sum:

- A) Users can't figure out how to use it, and:
- B) Developers don't have a middle ground between improving on the current ecosystem (thus adopting its current problems and working _backward_ to solve a limited subset of things it can), or creating new systems (which, despite the profundity of the idea, is so difficult to do—see all the many layers above!—that only one has even tried: [Guix](https://guix.gnu.org/), and its community is very small).

## Enter Kai

Kai proposes a middle way. Kai acknowledges two fundamental facts:

1. Nix dominance
2. Nix "Accidental Complexity"

Nix has the [largest package ecosystem](https://www.reddit.com/r/NixOS/comments/1n5dgpb/why_nixos_has_one_of_the_largest_repository_un/) in the world. A stunning achievement for a package manager which isn't the most well used, and an easy testament to the power of how reproducible software allows you to *ship*. Aside from that, it has seen slow increased adoption over the years despite continually fracturing communities and continuously deprecating APIs: even frontier LLMs get frequently confused about the best way to use Nix, because so much of the documentation teaches deprecated practices! Finally, there are no *real* competitors: imagine trying to build a *completely unique* package manager which uses a custom language and build a custom operating system from it while maintaining the largest package ecosystem on Earth, *without* being a for-profit company. Despite valid criticisms of Nix, this is a staggering achievement! One that is *extremely* difficult to replicate.

On the other hand, Nix suffers from so many problems which don't need to exist. I sometimes wonder if its creator, [Eelco Dolstra](https://edolstra.github.io/), thought that some enterprisers would take his idea and carry it out to permanently improve the world by eliminating the whole class of [software deployment problems](https://edolstra.github.io/pubs/nspfssd-lisa2004-final.pdf), in the way that, say, Rust did for programmers. Maybe he, like Benjamin Franklin when he named the poles of electricity positive and negative, thought that someone would take his discovery and formalize it more appropriately and give them better names, whereas instead, we are just stuck with these terms, and we are still stuck with Franklin's conceptual mistake of inverting the logical poles. And thus we are still stuck with many of the tradeoffs of Nix that are probably not worth having, despite the scope of the downstream improvements of using it over our current imperative systems being enormous and fundamental. Here we are over twenty years later, still building on top of inferior foundations. A huge portion of this I think is to be blamed on Nix's design at basically every level.

Taking these into account, Kai proposes to do the following:

1. Be backward compatible with Nix. Indeed, to simply *use* Nix directly under the hood at first.
2. Remove as much accidental complexity from using Nix as possible. Primarily through simplified UX and useful missing features or abstractions.

Alan Kay's motto is my North Star here: "Simple things should be simple; complex things should be possible." That is, make Nix (via Kai) as easy as possible to use while allowing users to do anything they'd normally be able to do in Nix (even modify/create raw Nix files where they find they can't do something in pure Kai).

This has resulted in me spending a lot of time seeking the appropriate [boundaries](https://www.destroyallsoftware.com/talks/boundaries) to expose. After settling on [Roc](https://roc-lang.org/) as the config language to use, I posted my idea on the [Roc forum](https://roc.zulipchat.com/), and to my amazement, Luke Boswell created a working prototype of my idea, [roc-blueprint](https://github.com/lukewilliamboswell/roc-blueprint), overnight!

This was great, as `roc-blueprint` provided an example of a general, pure, typed, and portable backend which could then be *lowered* into a compatible backend of choice (i.e. any reproducible system). In reality there are only two: Nix and Guix. Then this lowered Roc representation (itself another platform) could be used to instantiate and run actual respective commands. For example, here's a program that provides a portable representation of a Nix shell which contains the `pokemonsay` program:

```roc
app [main!] {
    pf: platform "https://github.com/lukewilliamboswell/roc-platform-template-zig/releases/download/1.0.0/AnZoxzoGPtSGQ15EQh6pBeeaHJ7aizP9MQhK81dES3Uq.tar.zst",
    blueprint: "../../blueprint/package.roc",
}

import pf.Stdout
import blueprint.Blueprint
import blueprint.Requirement
import blueprint.Target
import blueprint.Environment
import blueprint.Nix

pokemonsay : Requirement
pokemonsay = Requirement.new({
    id: "pokemonsay",
    display_name: "Pokemonsay Program",
})

workspace : Blueprint.Draft
workspace = Blueprint.workspace({
    name: "pokemonsay shell",
    target_systems: [Target.X86_64Linux],
    envs: [
        Environment.new({
            name: "default",
            requirements: [pokemonsay],
        }),
    ],
})

nix_config : Nix.Config
nix_config = Nix.config({
    nixpkgs: Nix.github_input(
        "nixpkgs",
        "NixOS",
        "nixpkgs",
        "nixos-unstable",
    ),
    bindings: [
        Nix.bind(
            pokemonsay,
            "nixpkgs",
            ["pokemonsay"],
        ),
    ],
})

main! : List(Str) => Try({}, _)
main! = |_args| {
    valid = Blueprint.validate(workspace) ? |errors| BlueprintInvalid(errors)
    source = Nix.render(valid, nix_config) ? |errors| NixInvalid(errors)
    Stdout.line!(source)?
    Ok({})
}
```

Cool! But notice any problems?

1. Boilerplate-galore! The actual `flake.nix` this renders is fewer lines than the config! (21 vs. 54)

```nix
# Generated by roc-blueprint and roc-blueprint-nix. Do not edit.
{
  "description" = "Development environments for pokemonsay shell";
  "inputs" = {
    "nixpkgs" = {
      "url" = "github:NixOS/nixpkgs/nixos-unstable";
    };
  };
  "outputs" = { nixpkgs, ... }:
    {
      "devShells" = {
        "x86_64-linux" = {
          "default" = nixpkgs."legacyPackages"."x86_64-linux"."mkShell" {
            "packages" = [
              nixpkgs."legacyPackages"."x86_64-linux"."pokemonsay"
            ];
          };
        };
      };
    };
}
```

So the resulting config file is more complex than what it is simplifying, with this caveat: we define the portable (`blueprint` platform) and the non-portable (`blueprint_nix` platform) in the same file, the benefit being we can reuse `blueprint` programmatically and theoretically have it port to any number of determinate system protocols under the hood (eventually, one config could boil down to a Nix *or* Guix system). Another benefit is we get strong typing: unlike `flake.nix`, the individual pieces are strongly typed and thus linters and checkers could be built upon this to much greater effect. So these are some great benefits, the strong typing and portability alone we may even call *Zero to One* benefits, but we have only achieved goal (1) above:

> Be backward compatible with Nix. Indeed, to simply *use* Nix directly under the hood at first.

But we've made (2) worse, adding complexity for arguably marginal gains for the average user:

> Remove as much accidental complexity from using Nix as possible. Primarily through simplified UX and useful missing features or abstractions.

There are also other problems: for example the user must have a compatible [Roc](https://roc-lang.org/) compiler installed, and they have to do `roc main.roc` to run it.

And even if we solve the above, this is an *incomplete* solution: the platform design is great, but must we really expect every user to just import this into their own programs, and write the logic to lower it?

I thought hard about what to do here, because the pros of this design are real, and I wanted to keep it for the time being as programmers might find this level of control useful, but for the vast majority of people a simpler config is in order. So I wrote one abstraction layer on top of it. Where the previous design looked like this:

```
[portable blueprint] -> [nix blueprint] -> [nix files]
```

The current one adds:

```
[kai.roc config] -> [portable blueprint] -> [nix blueprint] -> [nix files]
```

The `kai.roc` sacrifices a bit more detail and control for simplicity and looks like this:

```roc
app [config] {
    kai: platform "../../platform/config.roc",
}

import kai.Kai

config : Kai.Config
config = {
    name: "pokemonsay shell",
    shell: {
        pkgs: ["pokemonsay"],
    },
}
```

Much better! 13 total lines, and only 5 are config that the user needs to consider in the base case! But the idea is that the user will be able to move down and use the tool at any layer of abstraction as suits their needs. I'm not sure whether I'll keep `roc-blueprint` at all yet, as the benefits of an intermediate representation between high-level abstraction and low-level control must be weighed against the need for maintenance simplicity, and I'm not sure yet of the value proposition when the simpler model exists.

To achieve this simplicity over `roc-blueprint`, we make some assumptions on:

- The distinction between a validated `blueprint` and a `Draft` workspace
- The `Environment` concept
- The machine architecture (we remove `Target.X86_64Linux` from above, for example)

But I think many of these decisions can appropriately be outsourced to under-the-hood management by a CLI tool, which is the second part of the solution.

For example, we don't have to encode the architecture in the config mandatorily if the CLI tool `kai` can just save those details in the config (or just default to building for all default/common systems).

Right now, the CLI can only do `kai shell`. It is dependent on your machine having Nix (and Nix is still hardcoded in) and most egregiously on being x86_64 Linux (sorry!), but this will be modularized away later.
