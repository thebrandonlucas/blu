# Bug Hunting Loop

Finder → Skeptic → Referee.

## Use It When

- you want a focused audit
- a release needs extra scrutiny
- single-agent review keeps missing bugs

## Read First

- `AGENTS.md`
- `.agents/context.md`
- `.agents/VERIFICATION.md`
- `.agents/loop-config.env`

## Run

```bash
.agents/hunting/run.sh --phase finder
.agents/hunting/run.sh --phase skeptic
.agents/hunting/run.sh --phase referee
```

Optional pre-seeded tasks:

```bash
.agents/hunting/run.sh --from-tasks
```

Final accepted findings should end up in `.agents/hunting/output/work-list.json`.
