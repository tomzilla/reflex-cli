#!/bin/bash
# Command Tracker Hook
# Fires on PostToolUse (Bash) — logs every command for pattern analysis.
# Zero overhead on success — only emits structured output when useful.

set -e

COMMAND="${CLAUDE_TOOL_INPUT:-}"
OUTPUT="${CLAUDE_TOOL_OUTPUT:-}"
EXIT_CODE="${CLAUDE_TOOL_EXIT_CODE:-0}"

# Skip empty commands
[ -z "$COMMAND" ] && exit 0

# Extract the primary command (first token, stripping common prefixes)
primary=$(echo "$COMMAND" | awk '{print $1}' | sed 's/^sudo //' | sed 's/^doas //')

# Only track real CLI commands (skip env vars, path assignments, cd only)
if echo "$COMMAND" | grep -qE '^(cd|export|local|const|echo|source)\s'; then
    exit 0
fi

# Sanitize — truncate very long commands
display_cmd=$(echo "$COMMAND" | cut -c1-200)

# Build usage log entry
TIMESTAMP=$(date +%s)
TRACK_DIR="${HOME}/.agent-cli/usage"
mkdir -p "$TRACK_DIR"

# Log command + exit code to daily rolling file
LOG_FILE="${TRACK_DIR}/commands-$(date +%Y-%m-%d).log"
echo "${TIMESTAMP}|${EXIT_CODE}|${display_cmd}" >> "$LOG_FILE"

exit 0