# Verification

Use the smallest check set that proves the touched behavior still works.

## Quick Check

```bash
bun run build
```

## Commands

| Check | Command | When |
|---|---|---|
| Build | `bun run build` | Any Elm or CSS change |
| Dev preview | `bun run dev` | Visual inspection needed |

## Change Matrix

| Change type | Minimum verification |
|---|---|
| Markdown content only | `bun run build` and spot-check `_site/` output |
| Elm layout changes | `bun run build` (Elm compiler catches type errors) |
| CSS / Tailwind changes | `bun run build` and visual check with `bun run dev` |
| config.json changes | `bun run build` |
| Docs only | Confirm referenced paths and commands still exist |

## Pre-Commit Checklist

- [ ] `bun run build` succeeds
- [ ] Changed behavior was visually verified if applicable
- [ ] Docs and agent files match the implementation
- [ ] Commit scope is one logical change
