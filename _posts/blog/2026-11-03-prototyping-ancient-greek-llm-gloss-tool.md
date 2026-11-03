---
title: "Prototyping a Tool for Ancient Greek LLM Gloss Generation"
description: "Introducing apo, a free and open-source CLI that uses LLMs to generate word-by-word glosses and prose translations of Ancient Greek."
date: 2026-11-03
tags: greek language-learning software open-source
project: "lyceum"
time: "07:58"
---

One of the original goals of [lyceum.quest](https://lyceum.quest) was to use LLMs to generate any data I felt was missing to help me learn Ancient Greek. This usually meant accurate word-by-word glosses and custom prose translations, because A) things like grammar/morphology have much more comprehensive publicly available datasets and tools (like the  [Opera Graeca Adnotata (OGA)](https://github.com/OperaGraecaAdnotata/OGA) and [Morpheus](https://github.com/perseids-tools/morpheus), respectively) due to their more rule-based nature  and B) because learning by  _reading_ lots of Ancient Greek, once I've learned the basic grammar rules, has given me the fastest improvement results in my own learning journey. Having full-verse and word-by-word translations has been most helpful to me in reconciling the discrepancy between the Greek words I'm reading and the meaning it's conveying to me. Having one or the other alone seems like missing a piece of the answer key and having to guess whether I got it correct (a method Ancient Greek books often seem to employ).

Therefore! Seeing as there's a whole world of both untranslated and, if translated, copyrighted, Ancient Greek out there, and that I personally have benefitted tremendously from my own LLM generated data, it seemed that it could help many people if I began to formalize my processes and publish both the code and data for how I'm creating these translations.

So, I built a CLI tool to make the whole process reproducible (as much as any LLM-involved process can be, anyway).

For now I'm calling it *`apo`* (Agent Prose Orchestrator, from the Greek *ἀπό* - meaning *from*). Everything here is free and open source. The code is MIT license, the data CC-by-SA 4.0 (due to using the OGA as a base).

You can download it from Github [here](https://github.com/lyceum-quest/apo/releases/tag/v0.1.0).

To get started, run:

```sh
apo init
```

Then `apo` will interactively ask you a couple questions to get started, login to your provider, choose a model, where your input files are, where to place the output directory, etc. The `./works` directory is important, make sure to place your CoNLL-U files in there.

After that, you can run `apo run --count <number>` and it will begin creating glosses and translations, which will end up in an enhanced CoNLL-U file at `apo-output/<work>/<model>/output.conllu`.

There is much more to do and this is very early stages, but if you have any ideas on how it can be improved, please reach out!
