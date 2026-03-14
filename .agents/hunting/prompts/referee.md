# Referee Prompt

Combine the Finder report and Skeptic review into the final work list.

## Goal

Produce only actionable, evidence-backed items.

## Output Format

Write `work-list.json` to the requested output path.

```json
[
  {
    "id": "BUG-001",
    "priority": "high",
    "title": "Short title",
    "files": ["path/to/file"],
    "why_it_matters": "Short impact statement",
    "verification": ["command or manual check"]
  }
]
```
