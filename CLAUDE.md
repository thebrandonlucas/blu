# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **blu.cx** - Brandon Lucas's personal website and blog. It's a static site built with Elmstatic (Elm-based static site generator) and Tailwind CSS.

## Build Commands

```bash
bun install          # Install dependencies
bun run dev          # Dev server with hot reload (watches Elm and markdown files)
bun run build        # Production build (Elm + minified Tailwind)
bun run build:tw     # Tailwind only (for quick style iterations)
```

## Architecture

**Directory Structure:**
- `_layouts/` - Elm modules that define page layouts
- `_posts/` - Markdown content organized by section (articles, blog, journal, snippets)
- `_resources/` - Assets (CSS, fonts, images, JavaScript)
- `_site/` - Generated output (do not edit directly)
- `config.json` - Elmstatic site configuration (title, RSS, tags)

**Elm Layout Modules:**
- `Elmstatic.elm` - Core framework: JSON decoders, layout primitives, HTML template generation
- `Home.elm` - Home page with filtered snippets grid and author bio
- `Page.elm` - Generic static pages with markdown rendering
- `Post.elm` - Individual posts with date/tag metadata
- `Posts.elm` - Post list view for section indexes
- `UI.elm` - Shared header component with logo and icon links

**Data Flow:**
1. Elmstatic reads markdown frontmatter from `_posts/`
2. Passes JSON to Elm layout modules
3. Elm decodes JSON and renders HTML
4. Tailwind processes `_resources/styles.src.css` → `_site/styles.css`
5. Static files written to `_site/`

## Content Conventions

**Frontmatter:**
```yaml
---
title: "Page Title"
date: 2025-01-29
tags: [bitcoin, software]
layout: "Post"  # Home, Page, Post, Posts, or Tag
---
```

**Snippets (home page sections):** Use fake dates (2000-01-XX) to control display order.

## Styling

Primary styling via Tailwind CSS. Custom styles for markdown rendering and fonts are in `_resources/styles.src.css`.

## Deployment

GitHub Actions workflow (`.github/workflows/deploy.yml`) builds and rsyncs to VPS on push to master.
