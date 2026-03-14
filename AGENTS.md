# AGENTS.md

blu-elmstatic uses a generic, cross-tool agent pack.

## Quick Reference

| Task | Read |
|---|---|
| Project context | `.agents/context.md` |
| Workflow selection | `.agents/WORKFLOWS.md` |
| Verification | `.agents/VERIFICATION.md` |
| Style rules | `.agents/rules/style.md` |
| Commit rules | `.agents/rules/commits.md` |
| Safety rules | `.agents/rules/safety.md` |
| Loop config | `.agents/loop-config.env` |
| Bug hunting loop | `.agents/hunting/AGENTS.md` |
| Bug fixing loop | `.agents/fixing/AGENTS.md` |
| Feature loop | `.agents/features/AGENTS.md` |
| Personality | `SOUL.md` |

## Project Overview

Personal website and blog (blu.cx) built with Elmstatic (Elm-based static site generator) and Tailwind CSS. Elm layout modules render markdown content into static HTML pages.

## Ground Rules

- Prefer the lightest workflow that can answer the question safely.
- Read focused docs first instead of carrying giant prompts around.
- Verify the touched behavior before committing.
- Keep commits scoped to one logical change.
- Do NOT edit files under `_site/` — they are generated output.

## Default Loop Pack

This project includes all three loop directories by default:
- `.agents/hunting/`
- `.agents/fixing/`
- `.agents/features/`

They are optional escalation paths, not the default for every task.
