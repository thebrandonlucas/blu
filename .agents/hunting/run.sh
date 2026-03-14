#!/usr/bin/env bash
set -euo pipefail

LOOP_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="$(cd -- "$LOOP_DIR/.." && pwd)"
PROJECT_DIR="$(cd -- "$AGENTS_DIR/.." && pwd)"
OUTPUT_DIR="$LOOP_DIR/output"
PROMPTS_DIR="$LOOP_DIR/prompts"
CONFIG_FILE="${LOOP_CONFIG_FILE:-$AGENTS_DIR/loop-config.env}"

mkdir -p "$OUTPUT_DIR"
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

usage() {
  echo "Usage:"
  echo "  .agents/hunting/run.sh --phase finder|skeptic|referee"
  echo "  .agents/hunting/run.sh --from-tasks"
}

maybe_run_agent() {
  local role="$1"
  local phase="$2"
  local prompt_file="$3"
  local output_file="$4"
  if [[ -n "${LOOP_AGENT_RUNNER:-}" ]]; then
    (
      cd "$PROJECT_DIR"
      export LOOP_ROLE="$role"
      export LOOP_PHASE="$phase"
      export LOOP_PROMPT_FILE="$prompt_file"
      export LOOP_OUTPUT_FILE="$output_file"
      export LOOP_PROJECT_ROOT="$PROJECT_DIR"
      eval "$LOOP_AGENT_RUNNER"
    )
  else
    echo "Prompt: $prompt_file"
    echo "Write output to: $output_file"
  fi
}

append_runtime_block() {
  local prompt_file="$1"
  local output_path="$2"
  shift 2
  {
    printf "
## Runtime Inputs

"
    printf -- "- project root: `%s`
" "$PROJECT_DIR"
    printf -- "- context: `.agents/context.md`
"
    printf -- "- verification: `.agents/VERIFICATION.md`
"
    for line in "$@"; do
      printf -- "- %s
" "$line"
    done
    printf "
## Output Path

`%s`
" "$output_path"
  } >> "$prompt_file"
}

phase=""
from_tasks=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase)
      phase="$2"
      shift 2
      ;;
    --phase=*)
      phase="${1#*=}"
      shift
      ;;
    --from-tasks)
      from_tasks=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "$from_tasks" -eq 1 ]]; then
  phase="finder"
fi

case "$phase" in
  finder)
    OUTPUT_PATH="$OUTPUT_DIR/finder-report.json"
    PROMPT_PATH="$OUTPUT_DIR/finder-prompt.md"
    cp "$PROMPTS_DIR/finder.md" "$PROMPT_PATH"
    extra=()
    if [[ "$from_tasks" -eq 1 ]]; then
      extra+=("task seed file: .agents/hunting/tasks.json")
    else
      extra+=("mode: live discovery")
    fi
    append_runtime_block "$PROMPT_PATH" "$OUTPUT_PATH" "${extra[@]}"
    [[ -f "$OUTPUT_PATH" ]] || printf "[]
" > "$OUTPUT_PATH"
    maybe_run_agent finder finder "$PROMPT_PATH" "$OUTPUT_PATH"
    echo "Next: .agents/hunting/run.sh --phase skeptic"
    ;;
  skeptic)
    [[ -f "$OUTPUT_DIR/finder-report.json" ]] || { echo "Missing $OUTPUT_DIR/finder-report.json" >&2; exit 1; }
    OUTPUT_PATH="$OUTPUT_DIR/skeptic-review.json"
    PROMPT_PATH="$OUTPUT_DIR/skeptic-prompt.md"
    cp "$PROMPTS_DIR/skeptic.md" "$PROMPT_PATH"
    append_runtime_block "$PROMPT_PATH" "$OUTPUT_PATH" "finder report: .agents/hunting/output/finder-report.json"
    [[ -f "$OUTPUT_PATH" ]] || printf "[]
" > "$OUTPUT_PATH"
    maybe_run_agent skeptic skeptic "$PROMPT_PATH" "$OUTPUT_PATH"
    echo "Next: .agents/hunting/run.sh --phase referee"
    ;;
  referee)
    [[ -f "$OUTPUT_DIR/finder-report.json" ]] || { echo "Missing $OUTPUT_DIR/finder-report.json" >&2; exit 1; }
    [[ -f "$OUTPUT_DIR/skeptic-review.json" ]] || { echo "Missing $OUTPUT_DIR/skeptic-review.json" >&2; exit 1; }
    OUTPUT_PATH="$OUTPUT_DIR/work-list.json"
    PROMPT_PATH="$OUTPUT_DIR/referee-prompt.md"
    cp "$PROMPTS_DIR/referee.md" "$PROMPT_PATH"
    append_runtime_block "$PROMPT_PATH" "$OUTPUT_PATH"               "finder report: .agents/hunting/output/finder-report.json"               "skeptic review: .agents/hunting/output/skeptic-review.json"
    [[ -f "$OUTPUT_PATH" ]] || printf "[]
" > "$OUTPUT_PATH"
    maybe_run_agent referee referee "$PROMPT_PATH" "$OUTPUT_PATH"
    echo "Done: review .agents/hunting/output/work-list.json"
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac
