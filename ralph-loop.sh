#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $(basename "$0") <prompt> <max_iterations>"
  exit 1
fi

PROMPT="$1"
MAX_ITERATIONS="$2"
PROGRESS_FILE="./ralph-progress.md"

SYSTEM_PROMPT="You have a progress file at $PROGRESS_FILE that persists across runs.

At the START of every run:
- Read $PROGRESS_FILE to understand what has already been done.
- Do NOT redo completed work.

As you work:
- Append brief progress notes to $PROGRESS_FILE so future runs know what happened.

When all tasks are FULLY complete:
- Append \`<promise>COMPLETE</promise>\` as the very last line of $PROGRESS_FILE."

# Clear/create the progress file
> "$PROGRESS_FILE"

for (( i=1; i<=MAX_ITERATIONS; i++ )); do
  echo "=== Iteration $i / $MAX_ITERATIONS ==="

  FULL_PROMPT="$PROMPT

(Check $PROGRESS_FILE for prior progress before starting.)"

  claude -p "$FULL_PROMPT" \
    --system-prompt "$SYSTEM_PROMPT" \
    --dangerously-skip-permissions \
    --output-format stream-json \
    --verbose

  # Check if progress file signals completion (last 5 lines to tolerate trailing whitespace)
  if tail -n 5 "$PROGRESS_FILE" | grep -q '<promise>COMPLETE</promise>'; then
    echo ""
    echo "=== Task completed on iteration $i ==="
    exit 0
  fi

  echo ""
  echo "=== Iteration $i finished, task not yet complete ==="
done

echo ""
echo "=== Reached max iterations ($MAX_ITERATIONS) without completion ==="
exit 1
