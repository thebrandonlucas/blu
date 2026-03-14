# Skeptic Prompt

Review each Finder claim adversarially.

## Goal

Reject weak, duplicate, or unsupported findings. Keep only claims with concrete evidence.

## Output Format

Write a JSON array to the requested output path.

```json
{
  "id": "BUG-001",
  "verdict": "accept or reject",
  "reasoning": "Why this claim holds or fails",
  "extra_evidence": ["file:line or command evidence"]
}
```
