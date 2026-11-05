# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **blu.cx** - Brandon Lucas's personal website and blog. It's a static site built with [folio](https://github.com/thebrandonlucas/folio): a Rust driver renders the Markdown, and `site.roc`, a Roc program, turns the documents into every page, feed and sitemap.

## Build Commands

[Kai](https://github.com/thebrandonlucas/kai) 0.0.11 or later provides the tools (`Kaifile.roc`), with a folio checkout beside this one (`../folio`):

```bash
kai run folio        # build ../folio's driver and platform host, once
kai run build        # → _site/
kai run test         # site.roc's tests
kai workflow ci      # check, test and build
kai shell            # roc, zig, cargo and the deploy tools
```

`site.roc` imports the platform from `../folio/platform/main.roc`. folio lives outside this repository, so the site is built by a task, not a sandboxed `kai build`.

## Architecture

- `site.roc` - the whole site: which documents exist, their URLs, and every page's HTML
- `_posts/<section>/YYYY-MM-DD-slug.md` - writing: `articles`, `blog`, `journal` (fragments), and `quotes`
- `_projects/<slug>.md` - projects (`tagline`, `url`, `repo`, `status`, `order`)
- `_pages/<slug>.md` - standalone pages (about, books, talks, …)
- `_resources/` - copied to the site as is: `style.css`, `site.js`, fonts, images, highlight.js
- `_site/` - generated output (do not edit)
- `config.json` - the tags Quill lets posts use

Quill publishes the writing repository's `articles/`, `blog/` and `journal/` into `_posts/`.

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

Quill builds the site with folio and runs `scripts/deploy.sh` after every publish: it copies `_site/` to a new release in `/var/www/blu-site/releases/` on the VPS and switches `/var/www/blu-site/current` (what Caddy serves) to it in one step. To deploy by hand: `kai run build && kai run deploy` from a machine the VPS accepts for `blu-deploy`. GitHub Actions no longer deploys: it can't build folio, which isn't on GitHub yet.
