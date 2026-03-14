#!/usr/bin/env bash
set -euo pipefail

LOOP_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="$(cd -- "$LOOP_DIR/.." && pwd)"
PROJECT_DIR="$(cd -- "$AGENTS_DIR/.." && pwd)"
OUTPUT_DIR="$LOOP_DIR/output"
FIXES_DIR="$OUTPUT_DIR/fixes"
PROMPTS_DIR="$LOOP_DIR/prompts"
HUNTING_WORKLIST="$AGENTS_DIR/hunting/output/work-list.json"
CONFIG_FILE="${LOOP_CONFIG_FILE:-$AGENTS_DIR/loop-config.env}"

mkdir -p "$FIXES_DIR"
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

VERIFY_TEST_CMD="${VERIFY_TEST_CMD:-}"
VERIFY_LINT_CMD="${VERIFY_LINT_CMD:-}"
VERIFY_TYPECHECK_CMD="${VERIFY_TYPECHECK_CMD:-}"
VERIFY_BUILD_CMD="${VERIFY_BUILD_CMD:-}"

usage() {
  echo "Usage:"
  echo "  .agents/fixing/run.sh --list"
  echo "  .agents/fixing/run.sh --bug BUG-001"
  echo "  .agents/fixing/run.sh --bug BUG-001 --continue"
  echo "  .agents/fixing/run.sh --bug BUG-001 --finalize"
}

slugify_bug() {
  printf "%s" "$1" | tr "[:upper:]" "[:lower:]" | tr -cs "a-z0-9" "-"
}

bug_dir() {
  printf "%s/%s" "$FIXES_DIR" "$(slugify_bug "$1")"
}

state_file() {
  printf "%s/state.env" "$(bug_dir "$1")"
}

load_state() {
  local bug_id="$1"
  local file
  file="$(state_file "$bug_id")"
  [[ -f "$file" ]] || return 1
  # shellcheck disable=SC1090
  source "$file"
}

save_state() {
  local bug_id="$1"
  local phase="$2"
  local verdict="$3"
  local dir
  dir="$(bug_dir "$bug_id")"
  mkdir -p "$dir"
  {
    printf "BUG_ID=%q
" "$bug_id"
    printf "CURRENT_PHASE=%q
" "$phase"
    printf "VERDICT=%q
" "$verdict"
  } > "$(state_file "$bug_id")"
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

run_gate() {
  local label="$1"
  local command="$2"
  local log_file="$3"
  if [[ -z "$command" ]]; then
    return 0
  fi
  {
    printf "## %s

" "$label"
    printf '```bash
%s
```

' "$command"
  } >> "$log_file"
  if (cd "$PROJECT_DIR" && bash -lc "$command") >> "$log_file" 2>&1; then
    printf "
Result: PASS

" >> "$log_file"
  else
    printf "
Result: FAIL

" >> "$log_file"
    return 1
  fi
}

run_verification_gates() {
  local log_file="$1"
  : > "$log_file"
  run_gate "Tests" "$VERIFY_TEST_CMD" "$log_file"
  run_gate "Lint" "$VERIFY_LINT_CMD" "$log_file"
  run_gate "Typecheck" "$VERIFY_TYPECHECK_CMD" "$log_file"
  run_gate "Build" "$VERIFY_BUILD_CMD" "$log_file"
}

list_bugs() {
  if [[ -f "$HUNTING_WORKLIST" ]]; then
    echo "Known bugs from .agents/hunting/output/work-list.json:"
    grep -Eo '"id"[[:space:]]*:[[:space:]]*"[^"]+"|"title"[[:space:]]*:[[:space:]]*"[^"]+"' "$HUNTING_WORKLIST" || true
  else
    echo "No work list yet. Use .agents/hunting/run.sh first or start with a manual bug ID."
  fi
}

start_tester() {
  local bug_id="$1"
  local dir repro prompt
  dir="$(bug_dir "$bug_id")"
  mkdir -p "$dir"
  repro="$dir/repro.md"
  prompt="$dir/tester-prompt.md"
  cp "$PROMPTS_DIR/tester.md" "$prompt"
  append_runtime_block "$prompt" "$repro"             "bug id: $bug_id"             "work list: .agents/hunting/output/work-list.json (if present)"
  [[ -f "$repro" ]] || printf "# Repro

" > "$repro"
  save_state "$bug_id" tester pending
  maybe_run_agent tester tester "$prompt" "$repro"
  echo "Next: .agents/fixing/run.sh --bug $bug_id --continue"
}

start_fixer() {
  local bug_id="$1"
  local dir repro notes prompt
  dir="$(bug_dir "$bug_id")"
  repro="$dir/repro.md"
  [[ -f "$repro" ]] || { echo "Missing $repro" >&2; exit 1; }
  notes="$dir/fix-summary.md"
  prompt="$dir/fixer-prompt.md"
  cp "$PROMPTS_DIR/fixer.md" "$prompt"
  append_runtime_block "$prompt" "$notes"             "bug id: $bug_id"             "tester output: ${repro#$PROJECT_DIR/}"
  [[ -f "$notes" ]] || printf "# Fix Summary

" > "$notes"
  save_state "$bug_id" fixer pending
  maybe_run_agent fixer fixer "$prompt" "$notes"
  echo "Next: .agents/fixing/run.sh --bug $bug_id --continue"
}

start_verifier() {
  local bug_id="$1"
  local dir notes gate_log verdict prompt
  dir="$(bug_dir "$bug_id")"
  notes="$dir/fix-summary.md"
  [[ -f "$notes" ]] || { echo "Missing $notes" >&2; exit 1; }
  gate_log="$dir/gate-checks.md"
  if ! run_verification_gates "$gate_log"; then
    echo "Verification gate failed. See $gate_log" >&2
    exit 1
  fi
  verdict="$dir/verdict.md"
  prompt="$dir/verifier-prompt.md"
  cp "$PROMPTS_DIR/verifier.md" "$prompt"
  append_runtime_block "$prompt" "$verdict"             "bug id: $bug_id"             "tester output: ${dir#$PROJECT_DIR/}/repro.md"             "fixer output: ${dir#$PROJECT_DIR/}/fix-summary.md"             "gate log: ${gate_log#$PROJECT_DIR/}"
  [[ -f "$verdict" ]] || printf "NEEDS_WORK

" > "$verdict"
  save_state "$bug_id" verifier pending
  maybe_run_agent verifier verifier "$prompt" "$verdict"
  echo "Next: .agents/fixing/run.sh --bug $bug_id --finalize"
}

finalize_bug() {
  local bug_id="$1"
  local dir verdict gate_log final verdict_word
  dir="$(bug_dir "$bug_id")"
  verdict="$dir/verdict.md"
  [[ -f "$verdict" ]] || { echo "Missing $verdict" >&2; exit 1; }
  gate_log="$dir/final-gates.md"
  if ! run_verification_gates "$gate_log"; then
    verdict_word="NEEDS_WORK"
  elif grep -qi '^NEEDS_WORK' "$verdict"; then
    verdict_word="NEEDS_WORK"
  else
    verdict_word="SHIP"
  fi
  final="$dir/final-status.md"
  {
    printf "# Final Status

"
    printf "Result: **%s**

" "$verdict_word"
    printf -- "- verdict file: `%s`
" "${verdict#$PROJECT_DIR/}"
    printf -- "- final gates: `%s`
" "${gate_log#$PROJECT_DIR/}"
  } > "$final"
  save_state "$bug_id" complete "$verdict_word"
  echo "Done: $final"
}

bug_id=""
should_continue=0
should_finalize=0
should_list=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bug)
      bug_id="$2"
      shift 2
      ;;
    --bug=*)
      bug_id="${1#*=}"
      shift
      ;;
    --continue)
      should_continue=1
      shift
      ;;
    --finalize)
      should_finalize=1
      shift
      ;;
    --list)
      should_list=1
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

if [[ "$should_list" -eq 1 ]]; then
  list_bugs
  exit 0
fi

[[ -n "$bug_id" ]] || { usage >&2; exit 1; }

if ! load_state "$bug_id"; then
  start_tester "$bug_id"
  exit 0
fi

if [[ "$should_finalize" -eq 1 ]]; then
  finalize_bug "$bug_id"
  exit 0
fi

if [[ "$should_continue" -eq 1 ]]; then
  case "$CURRENT_PHASE" in
    tester) start_fixer "$bug_id" ;;
    fixer) start_verifier "$bug_id" ;;
    verifier) finalize_bug "$bug_id" ;;
    complete) echo "Already complete: $VERDICT" ;;
    *) echo "Unknown phase: $CURRENT_PHASE" >&2; exit 1 ;;
  esac
  exit 0
fi

echo "Current phase: $CURRENT_PHASE"
echo "Use --continue or --finalize"
