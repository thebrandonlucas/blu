# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **blu.cx** - Brandon Lucas's personal website and blog. Two Roc programs draw it from the same documents:

- `site.roc`, on [folio](https://github.com/thebrandonlucas/folio) (a Rust driver renders the Markdown), writes every page as static HTML, the feeds, the sitemap, and `data/site.json`: every published document, already read.
- `signals/`, a [roc-signals](https://github.com/lukewilliamboswell/roc-signals) 0.5.0 app, draws the same pages in the browser from `data/site.json` and moves between them without loading a page.

A page opens as folio's HTML (in `#static`, readable without JavaScript and by link previews and crawlers). `site.js` mounts the app beside it (in `#app`); once the app has drawn the page, it takes `#static` away. If the app can't start, the static page stays.

## Build Commands

[Kai](https://github.com/thebrandonlucas/kai) 0.0.12 or later provides the tools (`Kaifile.roc`), with a folio checkout beside this one (`../folio`):

```bash
kai run folio          # build ../folio's driver and platform host, once
kai run build          # → _site/ (with the app in _resources/app/)
kai run test           # packages/blu/'s tests, on folio's compiler
kai run build-signals  # rebuild the app into _resources/app/; commit it
kai run specs          # the app's specs (signals/specs/), natively
kai workflow ci        # check, test and build both, run the specs, and check the committed app is current
kai shell              # roc (folio's), zig, cargo and the deploy tools
kai shell signals      # roc (the app's)
```

`site.roc` imports the platform from `../folio/platform/main.roc`. folio lives outside this repository, so the site is built by a task, not a sandboxed `kai build`.

The two programs use two compilers: folio's pinned nightly (2026-09-26) and the one roc-signals 0.5.0 was tested with (2026-11-11). `packages/blu/` is shared by both, so it must build on both (`kai run test` and `kai run test-signals`).

The app is built with `--specialize=no`: specializing makes its module 7× larger and its build 20× slower, for speed the pages don't need. Its build is reproducible; `kai run verify-signals` fails if `_resources/app/app.wasm` isn't what `signals/` builds.

## Architecture

- `site.roc` - which documents exist and every page's HTML, the feeds, the sitemap and `data/site.json`
- `packages/blu/` - what both programs know: the site's documents (`Site`), dates, which page an address shows (`Route`), and the JSON the app reads (`Data`)
- `signals/` - the app: its store (`BluStore`: location, navigation, data), what each page shows (`Model`), and how it's drawn (`Pages`, `Parts`), with the same markup and classes as `site.roc`
- `scripts/signals.roc` - builds the app, verifies it, and runs its specs
- `_posts/<section>/YYYY-MM-DD-slug.md` - writing: `articles`, `blog`, `journal` (fragments), and `quotes`
- `_projects/<slug>.md` - projects (`tagline`, `url`, `repo`, `status`, `order`)
- `_pages/<slug>.md` - standalone pages (about, books, talks, …)
- `_resources/` - copied to the site as is: `style.css`, `site.js` (mounts the app; `<blu-markup>` shows a document's HTML), the built app in `app/`, fonts, images, highlight.js
- `_site/` - generated output (do not edit)
- `config.json` - the tags Quill lets posts use

Quill publishes the writing repository's `articles/`, `blog/` and `journal/` into `_posts/`.

A change to a page's markup goes in both `site.roc` and `signals/Pages.roc`.

## Content Conventions

```yaml
---
title: "Title"            # optional for journal fragments
description: "One sentence for lists and link previews."
date: 2026-10-08          # the file name's date is the one used
tags: nix software
series: kai-devlog        # optional: posts in a series link to each other
project: kai              # optional: lists the post on that project's page
type: fragment            # optional: overrides the section's kind
status: draft             # draft or private hide a document
---
```

Documents dated after the build day are hidden until then. Posts whose slug contains a project's slug are listed on that project's page without `project:`.

## Deployment

Quill builds the site with folio and runs `scripts/deploy.sh` after every publish (the app is in `_resources/app/`, so publishing needs nothing more): it copies `_site/` to a new release in `/var/www/blu-site/releases/` on the VPS and switches `/var/www/blu-site/current` (what Caddy serves) to it in one step. To deploy by hand: `kai run build && kai run deploy` from a machine the VPS accepts for `blu-deploy`. GitHub Actions no longer deploys: it can't build folio, which isn't on GitHub yet.
