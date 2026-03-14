# Feature Loop

Architect → Builder → Breaker.

## Use It When

- a feature needs a written spec first
- wrong assumptions are expensive
- you want an explicit adversarial pass before shipping

## Run

```bash
.agents/features/run.sh --feature "add search"
.agents/features/run.sh --feature "add search" --approve
.agents/features/run.sh --feature "add search" --continue
.agents/features/run.sh --feature "add search" --finalize
```

Human review after Architect is mandatory.
