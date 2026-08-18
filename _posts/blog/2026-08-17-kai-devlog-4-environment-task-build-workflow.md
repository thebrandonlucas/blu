---
title: "Kai Devlog #4: Environment, Task, Build, Workflow"
description: Expanding Kai with reusable environments, runnable tasks, composable workflows, portable builds, and overlays.
date: 2026-08-17
tags: nix software open-source
layout: "Post"
---

This release of `kai` is all about new features!

A lot of upfront work went into ensuring modular design, especially so that new features could be added relatively cleanly under a contract that I liked. The abstractions aren't perfect yet by any means, and it may still be a little confusing for a newcomer writing their own plugin. We'll work more on that in some future release.

But I did feel it was good enough to finally build more of the features that would put `kai` to good use. That said, here are the features currently available in `kai`. These examples are all available in the latest code release:

As before, you could enter shells with certain programs:

```Kaifile
# The simplest possible Kaifile.
#
# Run `kai shell` to enter this environment on Linux or macOS.
shell {
  packages: ["cowsay", "fortune"]
}
```

But now we have a more generic `environment` builtin which can be used to describe the same package set across the other new keys. For example: you can now create `task`s and run them via `kai run <task name>`

```Kaifile
# Run `kai run moo` to make the cow say a pithy quote!
environment cow {
  packages: ["cowsay", "fortune"]
}

task moo {
  environment: "cow"
  run: ["sh", "-c", "fortune | cowsay"]
}
```

Try running this with `kai run moo`!

You can also run `task`s together as part of a `workflow` (think CI). Run the below via `kai run cowvolution`:

```Kaifile
# Workflows compose tasks and builds into one repeatable command.
# Run this one with `kai workflow cowvolution`.
environment cow {
  packages: ["cowsay"]
}

task normalcow {
  environment: "cow"
  run: ["cowsay", "moo"]
}

task antiquitycow {
  environment: "cow"
  run: ["cowsay", "Non nobis solum nati sumus."]
}

task victoriancow {
  environment: "cow"
  run: ["cowsay", "doth mother know you weareth her drapes?"]
}

workflow cowvolution {
  steps: [
    "run normalcow",
    "run antiquitycow",
    "run victoriancow",
  ]
}
```

What if you want to package things together into a portably `build`-able derivation? You can! Here's a little shell script which will combine `cowsay` and `fortune` to have the `fortune` piped into whatever `cowsay` has to say. Run via `kai build <output-name>` (in this case `wisecow`)

```Kaifile
# You can build artifacts using the build command!
#
# This one combines `cowsay` and `fortune` to give you a
# `wisecow` binary.

environment cow {
  packages: ["cowsay", "fortune"]
}

build wisecow {
  environment: cow
  run: [
    "sh",
    "-c",
    "printf '#!%s\\n%s | %s\\n' \"$(command -v sh)\" \"$(command -v fortune)\" \"$(command -v cowsay)\" > wisecow && chmod +x wisecow"
  ]
  output: "wisecow"
}
```

Finally, we have `overlay`s, to help people run things that may not be in `nixpkgs` (`kai` itself needs this ability)

```Kaifile
# Overlays add packages that are not provided directly by nixpkgs.
shell {
  packages: ["rocpkgs.nightly"]
  overlays: ["github:thebrandonlucas/roc-overlay"]
}
```

That's it for now! Stay tuned!
