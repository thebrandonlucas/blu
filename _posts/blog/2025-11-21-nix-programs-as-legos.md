---
title: Stack Programs Like Legos with Nix!
description: Learn how to stitch programs together reprodicibly with Nix
date: 2025-11-21
tags: nix software open-source
---

Nix was made to solve the _software deployment problem_, concisely defined by creator Eelco Dolstra thus:

> [The software deployment problem] is about getting computer programs from one machine to another—and having
> them still work when they get there.
>
> The Purely Functional Software Deployment Model, Eelco Dolstra

Nix allows you to setup software on your computer in such a way that your setup is _reproducible_, meaning your setup on machine A can be _exactly_ the same as your setup on machine B -- as long as you have Nix.

To most people, learning Nix is a pain, due to the new concepts, sparse and outdated documentation, and community infighting.

But I think Nix can make using computers _fun_ and _powerful_ and _less painful_, once you learn how to handle its' edges.

One fun way we can use Nix is to stitch together programs like Legos and have them interact with each other in a reproducible way. Let's create an example!

First [install Nix](https://nixos.org/download/) if you haven't.

Say we have a fun little `bash` script like this:

```sh
#!/usr/bin/env bash

# filename: pokefortune.sh

message="${1:-}"
pokemon="${2:-slowking}"

# Silence Perl locale warnings.
export LC_ALL=C

# Generate a fortune if user did not pass a message.
if [[ -z "$message" ]]; then
  message=$(fortune)
fi

echo "$message" | pokemonsay -p "$pokemon" -n
```

It optionally takes in a message and a [Pokédex](https://pokemondb.net/pokedex/all) number, and prints out that Pokémon and message using the `pokemonsay` program. If either the message or the Pokemon aren't specified, it uses a default Pokemon and the program `fortune` to generate the message.

Save this in a file `pokefortune.sh`, make it executable, then run it:

```sh
# Make the bash script executable
chmod +x pokefortune.sh

./pokefortune.sh
```

If you're like most people, you probably don't have `pokemonsay` or `fortune` installed on your system, so you'll likely see something like this:

```sh
./pokefortune.sh: line 6: fortune: command not found
./pokefortune.sh: line 7: pokemonsay: command not found
```

Therefore this script, which works on my system because I have these programs installed, isn't _reproducible_ on your system. Let's create a Nix _derivation_ to make it so. Create a file called `pokefortune.nix` and copy the following:

```nix
# filename: pokefortune.nix

{
  pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz") { },
}:
pkgs.writeShellScriptBin "pokefortune" ''

message="''${1:-}"
pokemon="''${2:-slowking}"

# Silence Perl locale warnings.
export LC_ALL=C

# Generate a fortune if user did not pass a message.
if [[ -z "$message" ]]; then
  message=''$(${pkgs.fortune}/bin/fortune)
fi

echo $message | ${pkgs.pokemonsay}/bin/pokemonsay -p "$pokemon" -n
''
```

Now run:

```sh
nix-build pokefortune.nix
```

This may take awhile, especially if this is your first time running Nix. Let's look at the output:

```sh
nix-build src/scripts/nix/pokefortune.nix
unpacking 'https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz' into the Git cache...
this derivation will be built:
  /nix/store/vg4zmghqcnhjbs8kqhx04xixvm36d3ik-pokefortune.drv
these 9 paths will be fetched (2.65 MiB download, 26.91 MiB unpacked):
  /nix/store/0vdf5mpd762bw53rgl5nkmhvzq8n4m0d-file-5.45
  /nix/store/77cdqhqprqbciyhzsnzmsk7azbk2xv6r-fortune-mod-3.20.0
  /nix/store/d0i8idmbb4jji9ml01xsqgykrbvm7dss-gnu-config-2024-01-01
  /nix/store/0554jm1l1qw1pcfqsliw91hnifn11w8m-gnumake-4.4.1
  /nix/store/2wp235bg03gykpixd9v2nyxp08w8xq8a-patchelf-0.15.0
  /nix/store/c5x32idp600dklz9n25q38lk78j5vwxb-pokemonsay-1.0.0
  /nix/store/pba53n11na87fs4c20mp8yg4j7qx1by2-recode-3.7.14
  /nix/store/zix67r268ihi4c362zw7c0989z12jmy7-stdenv-linux
  /nix/store/2329271b42wh6b6yhl7jmjyi0cs4428b-update-autotools-gnu-config-scripts-hook
copying path '/nix/store/d0i8idmbb4jji9ml01xsqgykrbvm7dss-gnu-config-2024-01-01' from 'https://cache.nixos.org'...
copying path '/nix/store/c5x32idp600dklz9n25q38lk78j5vwxb-pokemonsay-1.0.0' from 'https://cache.nixos.org'...
copying path '/nix/store/0vdf5mpd762bw53rgl5nkmhvzq8n4m0d-file-5.45' from 'https://cache.nixos.org'...
copying path '/nix/store/0554jm1l1qw1pcfqsliw91hnifn11w8m-gnumake-4.4.1' from 'https://cache.nixos.org'...
copying path '/nix/store/2wp235bg03gykpixd9v2nyxp08w8xq8a-patchelf-0.15.0' from 'https://cache.nixos.org'...
copying path '/nix/store/pba53n11na87fs4c20mp8yg4j7qx1by2-recode-3.7.14' from 'https://cache.nixos.org'...
copying path '/nix/store/2329271b42wh6b6yhl7jmjyi0cs4428b-update-autotools-gnu-config-scripts-hook' from 'https://cache.nixos.org'...
copying path '/nix/store/zix67r268ihi4c362zw7c0989z12jmy7-stdenv-linux' from 'https://cache.nixos.org'...
copying path '/nix/store/77cdqhqprqbciyhzsnzmsk7azbk2xv6r-fortune-mod-3.20.0' from 'https://cache.nixos.org'...
building '/nix/store/vg4zmghqcnhjbs8kqhx04xixvm36d3ik-pokefortune.drv'...
/nix/store/vsv2spw517cwq791fl3f8iymm6hshhyq-pokefortune
```

Nix fetched the packages we specified in our `.nix` file: `pokemonsay`, `fortune`, and some we didn't specify: such as `file`, `patchelf`, and `recode`, which one or both of the other two packages depends on. Then it copied them locally, built a binary, and placed it at `/nix/store/vsv2spw517cwq791fl3f8iymm6hshhyq-pokefortune/bin`. We can confirm this by running it:

```sh
/nix/store/vsv2spw517cwq791fl3f8iymm6hshhyq-pokefortune/bin
```

You should see something like this:

<img src="/images/blog/nix-programs-as-legos/img_2_pokefortune.png" alt="pokefortune result" width="400">

To be reproducible, Nix ensures that it knows about every single dependency needed to create a package at all times. Because of that, you can do fun things like this:

```sh
# Quickly enter a shell with the dependencies to create and display images.
nix-shell -p graphviz chafa

# Query the derivation's dependency graph, create a .png from it and display it:
    nix-store --query --graph $(nix-build pokefortune.nix) | \
    dot -Tpng -o pokefortune-dependency-graph.png && chafa pokefortune-dependency-graph.png
```

Resulting in a view of every single dependency (the "closure") that our `pokefortune` program requires:

<!-- <div style="text-align: center;"> -->

![pokefortune result]()

<!--   <img src="assets/introduction/intro_img_3_pokefortune_dependency_graph.png" alt="pokefortune result"  height="600"> -->
<!-- </div> -->

How cool is that! We can see the whole dependency tree for anything packaged with Nix!

You have just done something very powerful with Nix: You've created a reproducible derivation that anyone who has the package manager installed on their system can use, which they couldn't before.

This is just a taste of what Nix can do, but I hope that the potential is clear. As Farid Zakaria says in his blog post "Learn Nix the Fun Way":

> Hopefully, seeing the fun things you can do with Nix might inspire you to push through the hard parts.
>
> There is a golden pot 💰 at the end of this rainbow 🌈 awaiting you.
>
> - <https://fzakaria.com/2024/07/05/learn-nix-the-fun-way>

---

_This article is directly inspired by Farid Zakaria's blog post [**Learn Nix the Fun Way**](https://fzakaria.com/2024/07/05/learn-nix-the-fun-way). Check out his excellent blog [here](https://fzakaria.com/)._

_Special thanks to [Russell Weas](https://github.com/russweas) and [veracius](https://veracius.dev) for their input to this article and code_

---

References:

- <https://edolstra.github.io/pubs/phd-thesis.pdf>
- <https://web.archive.org/web/20171017151526/http://aptitude.alioth.debian.org/doc/en/pr01s02.html>
- <https://fzakaria.com/2024/07/05/learn-nix-the-fun-way>
- <https://zero-to-nix.com/start/nix-run/>
