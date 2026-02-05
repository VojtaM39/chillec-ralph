#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $(basename "$0") <prompt> <max_iterations>"
  exit 1
fi

PROMPT="$1"
MAX_ITERATIONS="$2"
PROGRESS_FILE="./ralph-progress.md"

# ANSI colors
CYAN=$'\033[36m'
GREEN=$'\033[32m'
DIM=$'\033[2m'
RESET=$'\033[0m'

# jq filter: pretty-print stream-json into interactive-style output
# Uses try/? guards so unexpected event shapes are silently skipped
read -r -d '' JQ_FILTER << 'JQEOF' || true
def tool_summary:
  if   .name == "Bash"  then (.input.description // .input.command // "")
  elif .name == "Read"  then .input.file_path
  elif .name == "Edit"  then .input.file_path
  elif .name == "Write" then .input.file_path
  elif .name == "Grep"  then .input.pattern
  elif .name == "Glob"  then .input.pattern
  elif .name == "Task"  then .input.description
  else (.input | tostring | .[0:80])
  end;

# Stream text deltas token-by-token
if .type == "stream_event" then
  ((.event // empty) |
    if .type == "content_block_delta" then
      (.delta // empty) |
      if .type == "text_delta" then .text
      else empty end
    else empty end)

# Tool calls from completed assistant messages
elif .type == "assistant" then
  ((.message.content // empty)[] |
    if .type == "tool_use" then
      "\n\u001b[36m> \(.name)\u001b[0m: \(tool_summary)\n"
    else empty end)

# Final result summary
elif .type == "result" then
  "\n\u001b[32m--- Done (\((.duration_ms // 0) / 1000 | floor)s, $\(.total_cost_usd // 0 | tostring | .[0:6])) ---\u001b[0m\n"

else empty end
JQEOF

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
    --verbose \
    --include-partial-messages \
  | jq -rj --unbuffered "$JQ_FILTER"

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
