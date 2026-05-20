# Reflex CLI

> Turn your agent's repeated script patterns into permanent commands.

## What It Does

Your AI agent writes the same kind of script over and over — a text parser here, a file filter there, slightly different each time. Reflex watches for this and consolidates the pattern into a single, reusable command you can call from your terminal.

```
Agent writes ~/tmp/parse_v1.py   → runs it
Agent writes ~/tmp/text_tool.py  → runs it
Agent writes ~/tmp/extract.py    → runs it
                                        ↓
Reflex: "You've written 3 text-parsing scripts in 30 days."
        "→ Build reflex parse"
                                        ↓
reflex parse --filter=error app.log
```

## The Two Modes

### 1. Observed patterns → shell aliases

Reflex tracks every Bash command. After 14 days it knows:
- `grep -r "TODO" src/ --include="*.ts"` — run 10x → suggest `alias greptodo=...`
- `git stash && git pull --rebase && git stash pop` — run 5x → suggest `git-sync` function
- `cd ~/projects/very-long-name/src/api` — run 4x → suggest `alias api=...`

### 2. Script families → reflex commands

Reflex detects when you're building the same tool repeatedly. When it does, it suggests `reflex build <name>` to create a permanent command in `~/.reflex-cli/bin/`.

Once installed: `reflex parse`, `reflex scrape`, `reflex build` — callable like any CLI tool, with `-h` help.

## Architecture

```
~/.reflex-cli/
├── reflex              ← master CLI (install to PATH)
├── bin/                ← your installed commands
│   └── parse.py
└── usage/
    ├── commands-YYYY-MM-DD.log  ← all bash commands
    └── scripts.log               ← script executions

Agent shell → reflex parse → ~/.reflex-cli/bin/parse.py
```

## Commands

### Agent commands (in conversation)

| Command | Description |
|---------|-------------|
| `/reflex` | Analyze 14-day logs, show all suggestions |
| `/reflex --top 20` | Most-used commands |
| `/reflex --patterns` | Only recurring patterns (3+) |
| `/reflex --install` | Write confirmed aliases to shell config |
| `/reflex build <name>` | Scaffold a new reflex command |

### Master CLI (terminal)

```
reflex list              show available commands
reflex add <script>      install a script to bin/
reflex remove <name>    uninstall a command
reflex new <name>        scaffold a new command
reflex help <cmd>        show command help
reflex <cmd> [args]      run an installed command
```

All commands support `-h` / `--help`.

## Example Session

```
> /reflex

📊 Command Usage Analysis (14 days)

📦 Script Family Detected: text parsing
  ~/tmp/parse_fast.py   — filter lines matching pattern
  ~/tmp/text_tool.py     — split on delimiter
  ~/tmp/extract.py       — extract matching lines
  → Consolidate into: reflex parse
    Flags: --filter, --delimiter, --match

🔝 Most Used Commands:
  1. git status           — 47x
  2. grep -r              — 23x

⚡ Alias Candidates:
  1. gs → git status      (saves 7 chars × 47 = 329 chars)

Run /reflex build parse to consolidate the script family.
Run /reflex --install to write aliases to shell config.
```

## Installing the Master CLI

```bash
cp reflex ~/.local/bin/reflex
chmod +x ~/.local/bin/reflex
```

Then from any terminal: `reflex list`, `reflex parse -h`, etc.

## Hook Setup

In your agent's `settings.json`:

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

Uses `${REFLEX_CLI_ROOT}` so it works regardless of working directory.

## Log Format

```
~/.reflex-cli/usage/commands-YYYY-MM-DD.log
TIMESTAMP|EXIT_CODE|COMMAND

~/.reflex-cli/usage/scripts.log
TIMESTAMP|EXIT_CODE|FULL_SCRIPT_PATH
```

## Requirements

- Unix-like system (macOS, Linux)
- bash, zsh, or fish
- `~/.local/bin/` in PATH (or any PATH location)