# Agent CLI — Local CLI Enhancement Agent

An agent skill that observes the commands your AI agent uses, identifies patterns that would benefit from being made permanent shell aliases/functions, and adds them to your host machine's shell configuration.

## Concept

Your AI agent executes hundreds of commands per session. Some become muscle memory — `git st`, `grep -r`, `curl -sL`. Others are complex chains repeated across sessions that could be simplified.

This plugin turns observed command patterns into real shell improvements on your machine.

## Architecture

```
Agent executes command
        ↓
command-track.sh hook fires (PostToolUse, Bash)
        ↓
Logs to ~/.agent-cli/usage/commands-YYYY-MM-DD.log
        ↓
/track analyzes 14-day rolling window
        ↓
Patterns flagged → suggestions generated
        ↓
/track --install writes to ~/.bashrc / ~/.zshrc / fish config
```

## File Structure

```
agent-cli/
├── CLAUDE.md              ← This file
├── README.md
├── settings.json           ← Plugin manifest
├── hooks/
│   ├── hooks.json          ← Hook registration
│   └── command-track.sh    ← The tracking hook
├── skills/
│   └── command-tracker/
│       └── SKILL.md        ← Main skill
├── agents/
│   └── pattern-analyst.md   ← Sub-agent for heavy analysis
└── reference/
    └── shell-config-guide.md
```

## Commands

| Command | Description |
|---------|-------------|
| `/track` | Analyze recent commands, show alias/function suggestions |
| `/track --top N` | Show most-used commands |
| `/track --patterns` | Show only recurring patterns (3+ uses) |
| `/track --install` | Write confirmed aliases to shell config |

## Key Principles

1. **Observer only** — never modifies anything without explicit `/track --install`
2. **Zero overhead** — hook is silent on success, only writes on command execution
3. **User controls adoption** — suggestions are offered, not auto-applied
4. **Cross-session persistence** — logs survive restarts, analyzed over 14-day window

## Platform Notes

Works on macOS and Linux. Detects current shell (`$SHELL`) and writes to the appropriate config file.

## Hook Configuration

When installed as a plugin, the hook is registered via `${AGENT_CLI_ROOT}` variable:

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "${AGENT_CLI_ROOT}/hooks/command-track.sh"
      }]
    }]
  }
}
```

**Important**: Use `${AGENT_CLI_ROOT}` — a relative path like `./hooks/command-track.sh` will silently fail when the agent runs from a different working directory.