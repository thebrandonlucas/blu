---
title: "Kai Devlog #3: Custom DSL & Plugin Modules"
description: Replacing Kai's embedded Roc config with a custom DSL and making plugin modules simpler, reusable, and validated.
date: 2026-08-11
tags: nix software open-source
layout: "Post"
---

Something that is bred into `kai`'s bones is the idea that if something is hard to use, it won't be used unless it *must* be. In the last devlog we made `kai` modular in that you could build your own plugins, but there were several problems:

- You had to write custom parsing logic (terrible!)
- They weren't strict definitionally and the concept of a `Backend` was unclear and vague (does that just mean `nix`? What if there is more than one requirement?)
- They were unvalidated. You could "do whatever you wanted" and received no help from `xkai` when you did something illogical
- Plugin modules themselves were not modular/reusable/easy to make

This release now updates that so the plugins should be much simpler to write, parsing is handled for you, a few validations are done by `xkai` to help ensure you built it right, and `Backend` was given a much stronger definition that represented the system much better.

Additionally, I made a custom DSL! Even though the previous *embedded* `roc` DSL was pretty thin, I realized I could make things much simpler if I made a custom one. The primary motivation to do it in an embedded language was to inherit things like conditional logic, but I really only needed it for switching between systems (e.g. `if system == linux then install ...`) and that alone did not justify the extra complexity. Plus, it would require every user to have both a determinate system installed like `nix` *and* the `roc` compiler. Instead, we remove that extra 30MB or so and the final `kai` binary comes out to about 600KB! This does come at the cost of a lot of gutsy config parsing and validation, which is annoying, but I think the tradeoff is worth it.

But the best part is now, the simplest `config.kai` (which I'll soon rename `Kaifile`) looks like this:

```Kaifile
shell {
    pkgs: ["cowsay"]
}
```

With just this, you'll be able to define reproducible dev environments! For changing behavior on different systems:

```Kaifile
on linux {
    shell {
        pkgs: ["cowsay"]
    }
}

on macos {
    shell {
        pkgs: ["pokemonsay"]
    }
}
```

Much simpler and straightforward than a `flake.nix`, that's for sure!

Onward!
