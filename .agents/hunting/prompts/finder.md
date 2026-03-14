# Finder Prompt

Find a short list of high-confidence bugs, risky assumptions, or missing verification gaps.

## Sources of Truth

- `AGENTS.md`
- `.agents/context.md`
- `.agents/VERIFICATION.md`
- `.agents/WORKFLOWS.md`

## Output Format

Write a JSON array to the requested output path.

Each item should look like:

```json
{
  "id": "BUG-001",
  "severity": "high",
  "title": "Clear, specific bug title",
  "files": ["path/to/file"],
  "evidence": ["file:line or command evidence"],
  "why_it_matters": "Short impact statement",
  "suggested_verification": ["command or manual check"]
}
```

Keep the list tight. Prefer fewer, better findings.
