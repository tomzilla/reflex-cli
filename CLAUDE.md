# Reflex CLI — Build Command Reflexes

An agent plugin that observes the CLI commands your agent executes, identifies recurring patterns, and installs shell aliases/functions to your host machine — turning observed patterns into automatic reflexes.

## Concept

Your AI agent executes hundreds of commands per session. Some become muscle memory — `git st`, `grep -r`, `curl -sL`. Others are complex chains repeated across sessions that could be simplified into shell functions.

Reflex CLI turns observed command patterns into real shell improvements on your machine.

## Architecture

```
Agent executes command
        ↓
command-track.sh hook fires (PostToolUse, Bash)
        ↓
Logs to ~/.reflex-cli/usage/commands-YYYY-MM-DD.log
        ↓
/reflex analyzes 14-day rolling window
        ↓
Patterns scored → suggestions generated
        ↓
/reflex --install writes to ~/.bashrc / ~/.zshrc / fish config
```

## File Structure

```
reflex-cli/
├── CLAUDE.md              ← This file
├── README.md
├── settings.json           ← Plugin manifest
├── hooks/
│   ├── hooks.json          ← Hook registration
│   └── command-track.sh    ← The tracking hook
├── skills/
│   └── reflex/
│       └── SKILL.md        ← Main skill (/reflex commands)
├── agents/
│   └── pattern-analyst.md  ← Sub-agent for heavy analysis
└── reference/
    └── shell-config-guide.md
```

## Commands

| Command | Description |
|---------|-------------|
| `/reflex` | Analyze recent commands, show alias/function suggestions |
| `/reflex --top N` | Show most-used commands |
| `/reflex --patterns` | Show only recurring patterns (3+ uses) |
| `/reflex --install` | Write confirmed aliases to shell config |

## Key Principles

1. **Observer only** — never modifies anything without explicit `/reflex --install`
2. **Zero overhead** — hook is silent on success, only writes on command execution
3. **User controls adoption** — suggestions are offered, not auto-applied
4. **Cross-session persistence** — logs survive restarts, analyzed over 14-day window

## Platform Notes

Works on macOS and Linux. Detects current shell (`$SHELL`) and writes to the appropriate config file.

## Hook Configuration

When installed as a plugin, the hook is registered via `${REFLEX_CLI_ROOT}` variable:

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "${REFLEX_CLI_ROOT}/hooks/command-track.sh"
      }]
    }]
  }
}
```

**Important**: Use `${REFLEX_CLI_ROOT}` — a relative path like `./hooks/command-track.sh` will silently fail when the agent runs from a different working directory.