---
title: "Kai Devlog #2: Modularity"
description: Building Kai around replaceable commands, extensible plugins, and custom determinate backends.
date: 2026-08-04
tags: nix software open-source
layout: "Post"
---

Read any classic book about software, and you'll find that it's supposed to be modular. Why? Because modular software that does something useful is software that will _last_, roughly in proportion to:

- Its usefulness
- Its modularity
- Its evangelistic efforts
- Its ease of use

I believe this has become orders of magnitude more important in the Age of AI, as _code_ (which was never the most expensive piece of the software development lifecycle anyway) has become incredibly cheap to produce. I also believe, perhaps controversially, that the principles of software development as established by its progenitors are *even more relevant*, with perhaps some tweaks and modifications.

A recurring theme, whether it be in such classics as the [Unix Philosophy](https://shop.elsevier.com/books/the-unix-philosophy/gancarz/978-0-08-094819-5) or [The Mythical Man-Month](https://www.informit.com/store/mythical-man-month-essays-on-software-engineering-anniversary-9780201835953) or [The Cathedral and the Bazaar](https://www.oreilly.com/library/view/the-cathedral/0596001088/) or modern works like [Working in Public](https://press.stripe.com/working-in-public), is that good software should be modular. Think of the success of [LEGO](https://www.lego.com/en-us/history/articles/lego-system-in-play). A wonderful toy that embodies the spirit of open source software. LEGO's have outlived many a toy because their design allows them endless reconfigurability and modifiability. If grandpa builds a castle from LEGO's, then dad can add a dragon, and son, having slain it, can finally give the freed princess' tower a long-overdue remodeling. This means that the efforts of the tower have not been lost, from grandpa to father to son, that there is a deeply human *history* and *personalization* to that tower. 

Code works the same way. Linux is the undisputed king of infrastructure OS, and will probably overcome Windows and Apple: as the latter continue to get worse, piling on more and more new bloatware on already inferior foundations, their software will become more and more intractable to fix while the former continues to get more featureful, more useable, more battle-tested.

Thus, a modular approach will allow the code to be more flexible, interoperable, changeable, robust, and last much longer.

## Making Kai Modular

The three concerns for `kai` modularity outlined in previous articles are:
- Allowing replacement of any standard command with custom logic
- Allowing commands to be added since we can't anticipate every use case
- Allowing piecemeal replacement of underlying `nix` or `guix` pain points (such as the famously slow `nix` evaluator) with custom interoperable solutions

I modeled the design after [`caddy`](https://caddyserver.com/), the best web server technology I've ever used, which has great defaults, is fantastically easy to use and configure, and is extremely [modular](https://caddyserver.com/docs/architecture).

I created a separate binary, called `xkai` (analagous to `caddy`'s `xcaddy`) which creates custom `kai` binaries which execute the behavior specified in a custom `Plugin.roc` file. For example, the "core library" of `kai` is `StdPlugin` which looks like this:

```roc
import kai.Plugin as PluginApi

# The standard plugin is pure. kai.roc imports its typed configuration
# constructor; only the generic executor performs the resulting actions.
# TODO: it's explicitly limited to nix for now. This might be long-term
# desirable behavior, but we may want to consider providing guix support
# out of the box as a fallback. Or keep it as a separate Guix plugin/binary.
StdPlugin := [].{
    ShellConfig : { pkgs : List(Str) }

    nix : PluginApi.Backend
    nix = PluginApi.Backend.{ name: "nix" }

  # Only support the nix backend for now
    backends = [nix]

  # We have one command, shell, which just creates a nix dev shell
  # with a flake and enters it.
    shell_command : PluginApi.Command
    shell_command = PluginApi.Command.{
        argv: [],
        backends,
        name: "shell",
    }

  # Whereas `shell` is a portable `Command` variable, `nix_shell`
  # is the actual implementation that tells the `kai` binary resulting
  # from `xkai build` on this plugin which side-effects to perform.
  #
  # Separating these two concepts is important - if we supported, say,
  # `guix shell`, then we could have one command in kai which would run
  # `guix shell` or `nix shell` depending on which system the user wanted
  # to use. So it's very flexible!
    nix_shell : PluginApi.Implementation
    nix_shell = PluginApi.Implementation.{
        actions: [
            WriteConfigUtf8({ path: ".kai/flake.nix" }),
            Exec({
                args: ["develop", "path:.kai#default"],
                command: nix.name,
            }),
        ],
        backend: nix,
        command: shell_command,
        requirement: Program(nix.name),
    }

    shell : ShellConfig -> {
        implementation : PluginApi.Implementation,
        rendered_config : Str,
    }
    shell = |shell_config| {
        implementation: nix_shell,
        rendered_config: StdPlugin.render_nix(
            shell_config.pkgs,
        ),
    }

  # Render the actual flake, which will be written to a managed
  # directory called `.kai`
    render_nix : List(Str) -> Str
    render_nix = |pkgs| {
        package_lines = pkgs.map(
            |pkg| "              nixpkgs.\"legacyPackages\".\"x86_64-linux\".\"${pkg}\"",
        )
        lines = [
            "{",
            "  inputs.nixpkgs.url = \"github:NixOS/nixpkgs/nixos-unstable\";",
            "  outputs = { nixpkgs, ... }: {",
            "    devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {",
            "      packages = [",
        ].concat(package_lines).concat([
            "      ];",
            "    };",
            "  };",
            "}",
        ])
        Str.join_with(lines, "\n")
    }
}

# Plugins are pure, so we can do cheap, no I/O tests!
expect {
    module_config = StdPlugin.shell({ pkgs: ["hello"] })
    module_config.implementation == StdPlugin.nix_shell and
        module_config.rendered_config.contains(".\"hello\"")
}
```

This means that plugin creators need only write this plugin file, run `xkai build` on it, and they have their own custom `kai` binary! Which is, of course, how I will also be developing `kai`.

Thinking through this design has been by far the most difficult aspect of this project so far, and required a lot of research up front. But I am profoundly satisfied with this architecture.

Although `kai` is still very much a prototype which needs much better testing, interface, and of course, feature work, this is beginning to feel like a very solid and extensible foundation which will allow not just me, but *anyone*, to easily contribute meaningfully to this in the future.

Onward!
