# Workflow Modes

Choose the lightest workflow that fits the task.

## Modes

| Mode | Use when | Output |
|---|---|---|
| Understand / design | Scope, architecture, or risks are unclear | Short plan with touched files and verification |
| Implement | Scope is settled | Code or docs plus verification |
| Review | You need a neutral bug/risk pass | Findings ordered by impact |
| Feature loop | A feature needs spec → build → break flow | Files under `.agents/features/output/` |
| Fixing loop | A bug needs reproduce → fix → verify flow | Files under `.agents/fixing/output/` |
| Hunting loop | You want an adversarial audit | Files under `.agents/hunting/output/` |

## Rules

- Re-plan if the implementation is broader than expected.
- Prefer targeted reads over giant always-loaded context.
- Use loops when ambiguity or verification burden is high, not by default.
- Stop and confirm before destructive actions.
