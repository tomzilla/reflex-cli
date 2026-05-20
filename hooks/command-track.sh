#!/bin/bash
# Reflex CLI — Command Tracker Hook
# Fires on PostToolUse (Bash) — logs every command for pattern analysis.
# Zero overhead on success — only emits structured output when useful.

set -e

COMMAND="${CLAUDE_TOOL_INPUT:-}"
EXIT_CODE="${CLAUDE_TOOL_EXIT_CODE:-0}"

# Skip empty commands
[ -z "$COMMAND" ] && exit 0

# Skip env/builtins that aren't real external commands
if echo "$COMMAND" | grep -qE '^(cd|export|local|const|echo|source)\s'; then
    exit 0
fi

# Extract the primary command (first token)
primary=$(echo "$COMMAND" | awk '{print $1}' | sed 's/^sudo //' | sed 's/^doas //')

# Detect if it's a script file (not in PATH, has path separator)
is_script=false
if echo "$COMMAND" | grep -qE '(^|\s)/'; then
    # Check if the path is a file
    first_arg=$(echo "$COMMAND" | awk '{print $1}')
    if [ -f "$first_arg" ] || echo "$first_arg" | grep -qE '\.(sh|bash|py|rb|js|ts)$'; then
        is_script=true
    fi
fi

# Sanitize — truncate very long commands
display_cmd=$(echo "$COMMAND" | cut -c1-200)

# Build usage log entry
TIMESTAMP=$(date +%s)
TRACK_DIR="${HOME}/.reflex-cli/usage"
mkdir -p "$TRACK_DIR"

LOG_FILE="${TRACK_DIR}/commands-$(date +%Y-%m-%d).log"
echo "${TIMESTAMP}|${EXIT_CODE}|${display_cmd}" >> "$LOG_FILE"

# Track script execution separately for pattern detection
if [ "$is_script" = true ]; then
    SCRIPT_LOG="${TRACK_DIR}/scripts.log"
    echo "${TIMESTAMP}|${EXIT_CODE}|${display_cmd}" >> "$SCRIPT_LOG"
fi

exit 0