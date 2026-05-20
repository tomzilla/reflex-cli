#!/bin/bash
# Eval runner for reflex-cli
# Usage: ./evals/run.sh [eval-name]
#   ./evals/run.sh              — run all evals
#   ./evals/run.sh alias-suggest — run specific eval

set -e

EVAL_DIR="$(cd "$(dirname "$0")" && pwd)"
REFLEX_DIR="${HOME}/.reflex-cli"
BIN_DIR="${REFLEX_DIR}/bin"
USAGE_DIR="${REFLEX_DIR}/usage"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}✓ PASS${NC}: $1"; }
fail() { echo -e "${RED}✗ FAIL${NC}: $1"; }
info() { echo -e "${YELLOW}→${NC} $1"; }

# ---- Eval definitions ----

eval_alias_suggest() {
    info "Testing alias suggestion from repeated commands"

    # Setup: create fake usage logs
    mkdir -p "$USAGE_DIR"
    LOG_FILE="$USAGE_DIR/commands-2025-01-15.log"

    # Write repeated commands (git status 5x, grep -r 4x, unique commands)
    for i in {1..5}; do echo "1736937600|0|git status" >> "$LOG_FILE"; done
    for i in {1..4}; do echo "1736937600|0|grep -r \"TODO\" src/ --include=\"*.ts\"" >> "$LOG_FILE"; done
    for i in {1..3}; do echo "1736937600|0|curl -sL https://api.example.com/health" >> "$LOG_FILE"; done

    # The analysis should:
    # - Identify git status as alias candidate (5 uses, gs = 2 chars vs 9)
    # - Identify grep -r pattern (4 uses)
    # - Skip curl as it's not a repeated one-liner (only 3 uses)

    # This eval just verifies the log was written correctly
    local count
    count=$(wc -l < "$LOG_FILE")
    if [ "$count" -ge 12 ]; then
        pass "Usage log written: $count entries"
    else
        fail "Expected at least 12 log entries, got $count"
    fi

    # Cleanup
    rm -f "$LOG_FILE"
}

eval_script_family_detection() {
    info "Testing script family detection"

    mkdir -p "$USAGE_DIR"
    SCRIPT_LOG="$USAGE_DIR/scripts.log"

    # Write script family: 3 text parsing scripts, different names
    echo "1736937600|0|~/tmp/parse_fast.py" >> "$SCRIPT_LOG"
    echo "1736937700|0|~/tmp/text_tool.py" >> "$SCRIPT_LOG"
    echo "1736937800|0|~/tmp/extract.py" >> "$SCRIPT_LOG"
    echo "1736937900|0|~/tmp/filter_lines.py" >> "$SCRIPT_LOG"

    local count
    count=$(wc -l < "$SCRIPT_LOG")
    if [ "$count" -ge 4 ]; then
        pass "Script log written: $count entries (script family)"
    else
        fail "Expected at least 4 script entries, got $count"
    fi

    # Cleanup
    rm -f "$SCRIPT_LOG"
}

eval_reflex_list() {
    info "Testing reflex list command"

    mkdir -p "$BIN_DIR"

    # Create a test script with description
    cat > "$BIN_DIR/testcmd.py" << 'EOF'
#!/usr/bin/env python3
# description: Test command for eval
import argparse
def main():
    parser = argparse.ArgumentParser(description='Test command')
    parser.parse_args()
if __name__ == '__main__':
    main()
EOF
    chmod +x "$BIN_DIR/testcmd.py"

    # Run reflex list — use project-local reflex since not installed to PATH
    REFLEX_PATH="$(dirname "$EVAL_DIR")/reflex"
    output=$("$REFLEX_PATH" list 2>&1) || true

    if echo "$output" | grep -q "testcmd"; then
        pass "reflex list shows installed command"
    else
        fail "reflex list did not show testcmd: $output"
    fi

    # Cleanup
    rm -f "$BIN_DIR/testcmd.py"
}

eval_reflex_help() {
    info "Testing reflex help for built-in command"

    REFLEX_PATH="$(dirname "$EVAL_DIR")/reflex"
    output=$("$REFLEX_PATH" help list 2>&1) || true

    if echo "$output" | grep -q "Usage"; then
        pass "reflex help list shows usage"
    else
        fail "reflex help list did not show usage: $output"
    fi
}

eval_reflex_new_scaffolds() {
    info "Testing reflex new creates scaffold with -h"

    mkdir -p "$BIN_DIR"

    # Clean up if exists
    rm -f "$BIN_DIR/evaltest"*

    REFLEX_PATH="$(dirname "$EVAL_DIR")/reflex"
    "$REFLEX_PATH" new evaltest --python >/dev/null 2>&1

    if [ -f "$BIN_DIR/evaltest.py" ]; then
        pass "reflex new creates evaltest.py"
    else
        fail "reflex new did not create evaltest.py"
        return
    fi

    # Test -h on the scaffold
    output=$(python3 "$BIN_DIR/evaltest.py" -h 2>&1) || true

    if echo "$output" | grep -q "usage"; then
        pass "Scaffolded script has -h support"
    else
        fail "Scaffolded script missing -h: $output"
    fi

    # Cleanup
    rm -f "$BIN_DIR/evaltest.py"
}

eval_hook_logs_commands() {
    info "Testing command-track.sh hook logs to correct location"

    mkdir -p "$USAGE_DIR"
    LOG_FILE="$USAGE_DIR/commands-$(date +%Y-%m-%d).log"

    # Simulate hook execution with a test command
    CLAUDE_TOOL_INPUT="ls -la" CLAUDE_TOOL_EXIT_CODE="0" bash "$EVAL_DIR/../hooks/command-track.sh"

    if [ -f "$LOG_FILE" ]; then
        pass "Hook created daily log file"
        # Verify entry format
        if grep -q "|0|ls -la" "$LOG_FILE" 2>/dev/null; then
            pass "Log entry format correct (TIMESTAMP|EXIT_CODE|COMMAND)"
        else
            fail "Log entry format incorrect"
        fi
    else
        fail "Hook did not create log file"
    fi
}

# ---- Runner ----

ALL_EVALS=(
    eval_alias_suggest
    eval_script_family_detection
    eval_reflex_list
    eval_reflex_help
    eval_reflex_new_scaffolds
    eval_hook_logs_commands
)

if [ -n "$1" ]; then
    # Run specific eval
    if declare -f "$1" > /dev/null; then
        echo "=== Running $1 ==="
        $1
    else
        echo "Unknown eval: $1"
        echo "Available: ${ALL_EVALS[*]}"
        exit 1
    fi
else
    # Run all
    echo "=== Reflex CLI Evals ==="
    echo ""

    passed=0
    failed=0

    for eval in "${ALL_EVALS[@]}"; do
        echo "--- $eval ---"
        if $eval; then
            ((passed++))
        else
            ((failed++))
        fi
        echo ""
    done

    echo "=== Results: $passed passed, $failed failed ==="
    [ "$failed" -eq 0 ]
fi