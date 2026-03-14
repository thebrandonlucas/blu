# Bug Fixing Loop

Tester → Fixer → Verifier.

## Use It When

- a bug is already known
- you want reproduce-first discipline
- a fix needs an adversarial final pass

## Run

```bash
.agents/fixing/run.sh --list
.agents/fixing/run.sh --bug BUG-001
.agents/fixing/run.sh --bug BUG-001 --continue
.agents/fixing/run.sh --bug BUG-001 --continue
.agents/fixing/run.sh --bug BUG-001 --finalize
```

Test and build gates come from `.agents/loop-config.env` and can be overridden with env vars.
