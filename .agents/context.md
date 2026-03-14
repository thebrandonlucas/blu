# Project Context

## Snapshot

- **Name:** blu-elmstatic
- **Type:** frontend (static site)
- **Primary language:** Elm + Tailwind CSS
- **Description:** Personal website and blog (blu.cx) built with Elmstatic and Tailwind CSS. Elm layout modules decode markdown frontmatter JSON and render static HTML.

## Repo Map

```text
blu-elmstatic/
├── config.json                 # Elmstatic site config (title, RSS, tags)
├── elm.json                    # Elm dependencies
├── package.json                # Bun scripts and JS dependencies
├── _layouts/                   # Elm layout modules
│   ├── Elmstatic.elm           # Core framework: decoders, layout primitives, HTML gen
│   ├── Home.elm                # Home page with snippets grid and author bio
│   ├── Page.elm                # Generic static pages with markdown rendering
│   ├── Post.elm                # Individual posts with date/tag metadata
│   ├── Posts.elm               # Post list view for section indexes
│   ├── Tag.elm                 # Tag page layout
│   ├── Styles.elm              # Elm CSS styles (elm-css)
│   └── UI.elm                  # Shared header component
├── _posts/                     # Markdown content
│   ├── articles/               # Long-form articles
│   ├── blog/                   # Blog posts
│   ├── journal/                # Journal entries
│   ├── snippets/               # Home page sections (fake dates for ordering)
│   └── index.md                # Posts index
├── _resources/                 # Static assets
│   ├── styles.src.css          # Tailwind source CSS
│   ├── fonts/                  # Web fonts
│   ├── images/                 # Images
│   ├── highlight/              # Syntax highlighting
│   ├── data/                   # JSON data files
│   ├── favicon.ico
│   └── robots.txt
├── _site/                      # Generated output (do not edit)
├── scripts/
│   └── generate-changelog.sh
└── AGENTS.md
```

## Commands

```bash
# Quick verify
bun run build

# Test
# (no test suite — verify by building and inspecting output)

# Lint
# (no linter configured)

# Typecheck
# (Elm compiler is the typechecker — runs during build)

# Build
bun run build
```

## Notes

- `bun run build` compiles Elm layouts + processes Tailwind CSS → `_site/`
- `bun run dev` starts dev server with file watching and browser-sync
- Elm compiler catches type errors during build, so build = typecheck
- Snippets use fake dates (2000-01-XX) to control display order on the home page
- Deployment: GitHub Actions builds and rsyncs `_site/` to VPS on push to master
- This project uses Git (not Jujutsu)
