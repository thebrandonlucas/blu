#!/usr/bin/env bash
set -euo pipefail

LOOP_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="$(cd -- "$LOOP_DIR/.." && pwd)"
PROJECT_DIR="$(cd -- "$AGENTS_DIR/.." && pwd)"
OUTPUT_DIR="$LOOP_DIR/output"
FEATURES_DIR="$OUTPUT_DIR/features"
PROMPTS_DIR="$LOOP_DIR/prompts"
CONFIG_FILE="${LOOP_CONFIG_FILE:-$AGENTS_DIR/loop-config.env}"

mkdir -p "$FEATURES_DIR"
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

VERIFY_TEST_CMD="${VERIFY_TEST_CMD:-}"
VERIFY_LINT_CMD="${VERIFY_LINT_CMD:-}"
VERIFY_TYPECHECK_CMD="${VERIFY_TYPECHECK_CMD:-}"
VERIFY_BUILD_CMD="${VERIFY_BUILD_CMD:-}"

usage() {
  echo "Usage:"
  echo "  .agents/features/run.sh --feature "name""
  echo "  .agents/features/run.sh --feature "name" --approve"
  echo "  .agents/features/run.sh --feature "name" --continue"
  echo "  .agents/features/run.sh --feature "name" --finalize"
  echo "  .agents/features/run.sh --list"
}

slugify() {
  printf "%s" "$1" | tr "[:upper:]" "[:lower:]" | tr -cs "a-z0-9" "-"
}

feature_dir() {
  printf "%s/%s" "$FEATURES_DIR" "$(slugify "$1")"
}

state_file() {
  printf "%s/state.env" "$(feature_dir "$1")"
}

load_state() {
  local feature_name="$1"
  local file
  file="$(state_file "$feature_name")"
  [[ -f "$file" ]] || return 1
  # shellcheck disable=SC1090
  source "$file"
}

save_state() {
  local feature_name="$1"
  local phase="$2"
  local approved="$3"
  local verdict="$4"
  local dir
  dir="$(feature_dir "$feature_name")"
  mkdir -p "$dir"
  {
    printf "FEATURE_NAME=%q
" "$feature_name"
    printf "FEATURE_SLUG=%q
" "$(slugify "$feature_name")"
    printf "CURRENT_PHASE=%q
" "$phase"
    printf "ARCHITECT_APPROVED=%q
" "$approved"
    printf "VERDICT=%q
" "$verdict"
  } > "$(state_file "$feature_name")"
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

ensure_structure() {
  local dir="$1"
  mkdir -p "$dir/1-architect" "$dir/2-builder" "$dir/3-breaker"
}

list_features() {
  if [[ ! -d "$FEATURES_DIR" ]]; then
    echo "No features yet."
    return
  fi
  find "$FEATURES_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f
' | sort
}

start_architect() {
  local feature_name="$1"
  local dir spec acceptance tests prompt
  dir="$(feature_dir "$feature_name")"
  ensure_structure "$dir"
  spec="$dir/1-architect/spec.md"
  acceptance="$dir/1-architect/acceptance.md"
  tests="$dir/1-architect/test-plan.md"
  prompt="$dir/1-architect/prompt.md"
  cp "$PROMPTS_DIR/architect.md" "$prompt"
  append_runtime_block "$prompt" "$spec"             "feature request: $feature_name"             "also write: ${acceptance#$PROJECT_DIR/}"             "also write: ${tests#$PROJECT_DIR/}"
  [[ -f "$spec" ]] || printf "# Spec

" > "$spec"
  [[ -f "$acceptance" ]] || printf "# Acceptance

" > "$acceptance"
  [[ -f "$tests" ]] || printf "# Test Plan

" > "$tests"
  save_state "$feature_name" architect 0 pending
  maybe_run_agent architect architect "$prompt" "$spec"
  echo "Review the architect output, then run:"
  echo ".agents/features/run.sh --feature "$feature_name" --approve"
}

start_builder() {
  local feature_name="$1"
  local dir notes prompt
  dir="$(feature_dir "$feature_name")"
  ensure_structure "$dir"
  prompt="$dir/2-builder/prompt.md"
  notes="$dir/2-builder/build-notes.md"
  cp "$PROMPTS_DIR/builder.md" "$prompt"
  append_runtime_block "$prompt" "$notes"             "feature request: $feature_name"             "approved spec: ${dir#$PROJECT_DIR/}/1-architect/spec.md"             "acceptance: ${dir#$PROJECT_DIR/}/1-architect/acceptance.md"             "test plan: ${dir#$PROJECT_DIR/}/1-architect/test-plan.md"
  [[ -f "$notes" ]] || printf "# Build Notes

" > "$notes"
  save_state "$feature_name" builder 1 pending
  maybe_run_agent builder builder "$prompt" "$notes"
  echo "Next: .agents/features/run.sh --feature "$feature_name" --continue"
}

start_breaker() {
  local feature_name="$1"
  local dir notes gate_log report prompt
  dir="$(feature_dir "$feature_name")"
  notes="$dir/2-builder/build-notes.md"
  [[ -f "$notes" ]] || { echo "Missing $notes" >&2; exit 1; }
  gate_log="$dir/2-builder/gate-checks.md"
  if ! run_verification_gates "$gate_log"; then
    echo "Verification gate failed. See $gate_log" >&2
    exit 1
  fi
  prompt="$dir/3-breaker/prompt.md"
  report="$dir/3-breaker/attack-report.md"
  cp "$PROMPTS_DIR/breaker.md" "$prompt"
  append_runtime_block "$prompt" "$report"             "feature request: $feature_name"             "approved spec: ${dir#$PROJECT_DIR/}/1-architect/spec.md"             "builder notes: ${notes#$PROJECT_DIR/}"             "gate log: ${gate_log#$PROJECT_DIR/}"
  [[ -f "$report" ]] || printf "NEEDS_WORK

" > "$report"
  save_state "$feature_name" breaker 1 pending
  maybe_run_agent breaker breaker "$prompt" "$report"
  echo "Next: .agents/features/run.sh --feature "$feature_name" --finalize"
}

finalize_feature() {
  local feature_name="$1"
  local dir report gate_log final verdict_word
  dir="$(feature_dir "$feature_name")"
  report="$dir/3-breaker/attack-report.md"
  [[ -f "$report" ]] || { echo "Missing $report" >&2; exit 1; }
  gate_log="$dir/3-breaker/final-gates.md"
  if ! run_verification_gates "$gate_log"; then
    verdict_word="NEEDS_WORK"
  elif grep -qi '^NEEDS_WORK' "$report"; then
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
    printf -- "- attack report: `%s`
" "${report#$PROJECT_DIR/}"
    printf -- "- final gates: `%s`
" "${gate_log#$PROJECT_DIR/}"
  } > "$final"
  save_state "$feature_name" complete 1 "$verdict_word"
  echo "Done: $final"
}

feature_name=""
should_list=0
should_approve=0
should_continue=0
should_finalize=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --feature)
      feature_name="$2"
      shift 2
      ;;
    --feature=*)
      feature_name="${1#*=}"
      shift
      ;;
    --list)
      should_list=1
      shift
      ;;
    --approve)
      should_approve=1
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
  list_features
  exit 0
fi

[[ -n "$feature_name" ]] || { usage >&2; exit 1; }

if ! load_state "$feature_name"; then
  start_architect "$feature_name"
  exit 0
fi

if [[ "$should_approve" -eq 1 ]]; then
  if [[ ! -f "$(feature_dir "$feature_name")/1-architect/spec.md" ]]; then
    echo "Missing architect outputs" >&2
    exit 1
  fi
  save_state "$feature_name" architect 1 pending
  start_builder "$feature_name"
  exit 0
fi

if [[ "$should_finalize" -eq 1 ]]; then
  finalize_feature "$feature_name"
  exit 0
fi

if [[ "$should_continue" -eq 1 ]]; then
  case "$CURRENT_PHASE" in
    architect)
      if [[ "$ARCHITECT_APPROVED" != "1" ]]; then
        echo "Architect output must be approved first" >&2
        exit 1
      fi
      start_builder "$feature_name"
      ;;
    builder) start_breaker "$feature_name" ;;
    breaker) finalize_feature "$feature_name" ;;
    complete) echo "Already complete: $VERDICT" ;;
    *) echo "Unknown phase: $CURRENT_PHASE" >&2; exit 1 ;;
  esac
  exit 0
fi

echo "Current phase: $CURRENT_PHASE"
echo "Approved: $ARCHITECT_APPROVED"
echo "Use --approve, --continue, or --finalize"
