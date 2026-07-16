---
title: "Packaging Roc Nightlies with a Nix Flake and Overlay"
description: Packaging official Roc nightly compiler binaries reproducibly with a Nix flake and overlay.
date: 2026-07-16
tags: nix software open-source
layout: "Post"
---

## Packaging Roc Nightlies with a Nix Flake and Overlay
 
[Mitchell Hashimoto](https://mitchellh.com/) built an excellent [Zig overlay flake](https://github.com/mitchellh/zig-overlay) which allows you to get the nightly version of the Zig compiler with a single Nix command. At the time of this writing, Zig 0.16.0 is the latest stable release. Some projects intentionally track Zig’s rapidly changing development branch instead. [Ziglings](https://codeberg.org/ziglings/exercises), for example, currently requires a sufficiently recent 0.17.0 development build and does not compile with Zig `0.16.0`! Although Zig's official binary can run on NixOS, integrating it reproducibly and ensuring host linking works correctly requires additional Nix setup. If `zig-overlay` didn't exist, I'd have had to roll a custom solution just for myself. An overlay/flake is thus useful for any project not considered stable to allow anyone to have a reproducible/pinnable or just bleeding-edge environment for any version indexed by the overlay. It makes compatibility and environment setup orders of magnitude easier to achieve. No more hunting down binaries! (or hunting down and patching if you're on NixOS).
 
The newer and more in flux the project, the more useful this is. And with the proven utility of the `zig-overlay` template, I decided to build one for an even newer programming language, [Roc](https://roc-lang.org/). At present, Roc releases [nightly](https://github.com/roc-lang/nightlies/releases) binaries of the compiler. They are currently replacing the Rust compiler with a new scratch Zig rewrite, which has breaking changes to Roc's design such that code and platforms targeting the old compiler are usually incompatible with the new compiler, and have not made a stable release of the Zig compiler [release](https://github.com/roc-lang/roc/releases) yet. Thus, there's a lot of incompatibility between apps which were built using the old and new Roc compilers, since the new compiler introduces a lot of backward-incompatible language features. So, being a nix enthusiast, I thought it would be helpful to create a `roc-overlay` modeled after `zig-overlay`, allowing tracked versions of the nightly compiler to be selected by a developer, or even better, declared as an input in `flake.nix` and pinned to an exact repository revision in `flake.lock` for given projects so the developer doesn't even have to think about which nightly to use.

### `roc-overlay` Contents

[`roc-overlay`](https://github.com/thebrandonlucas/roc-overlay) provides a Nix flake for the official Roc new-compiler binaries. It installs prebuilt archives and does not build from source. It mirrors `zig-overlay` in overall structure. Use it like this:  
  
```bash
# To get the latest nightly as seen by the repo,
# run one of these:

# Create a shell with the compiler.
nix shell github:thebrandonlucas/roc-overlay
roc version

# Run one-off commands directly from the flake.
nix run github:thebrandonlucas/roc-overlay -- version
```

Including the overlay in your `flake.nix`:

```nix
   {
     inputs = {
       nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
       roc-overlay.url = "github:thebrandonlucas/roc-overlay";
     };

     outputs = { nixpkgs, roc-overlay, ... }:
       let
         system = "x86_64-linux";
         pkgs = import nixpkgs {
           inherit system;
           overlays = [ roc-overlay.overlays.default ];
         };
       in
       {
         devShells.${system}.default = pkgs.mkShell {
           packages = [ pkgs.rocpkgs.nightly ];
         };
       };
   }
```

Hopefully you find this overlay useful. Please [open an issue](https://github.com/thebrandonlucas/roc-overlay/issues/new) if you find anything that needs improvement.
