# Reflex CLI

> Build command reflexes — turn your agent's patterns into shell shortcuts.

An agent plugin that observes CLI commands your agent executes, identifies recurring patterns, and suggests — then installs — shell aliases and functions to your host machine.

## What It Does

1. **Tracks** every Bash command your agent runs (via a lightweight hook)
2. **Analyzes** the last 14 days of usage to find patterns
3. **Suggests** aliases and functions with the highest ROI
4. **Installs** confirmed suggestions to your shell config (`~/.bashrc`, `~/.zshrc`, or fish)

## Commands

| Command | Description |
|---------|-------------|
| `/reflex` | Analyze recent commands, show all suggestions |
| `/reflex --top 20` | Show top 20 most-used commands |
| `/reflex --patterns` | Show only patterns (3+ uses) |
| `/reflex --install` | Write confirmed aliases to shell config |

## Example Session

```
> /reflex

📊 Command Usage Analysis (14 days)

🔝 Most Used Commands:
  1. git status           — 47x
  2. grep -r              — 23x
  3. curl -sL             — 19x
  4. npm run              — 15x

⚡ Alias Candidates:
  1. gs → git status      (saves 7 chars × 47 = 329 chars)
  2. grepr → grep -r     (saves 4 chars × 23 = 92 chars)

💡 Recommended:
  alias gs='git status'
  alias gl='git log --oneline --graph --decorate'

Run /reflex --install to write these to your shell config.
```

## How It Works

```
Command executed → hook fires → logs timestamp + command + exit code
                                    ↓
                            Rolling 14-day log files
                                    ↓
                    /reflex reads and analyzes patterns
                                    ↓
                    Suggestions generated (score ≥ 5)
                                    ↓
                    /reflex --install writes to shell config
```

## Log Location

```
~/.reflex-cli/usage/commands-YYYY-MM-DD.log
```

Format: `TIMESTAMP|EXIT_CODE|COMMAND`

## Requirements

- Unix-like system (macOS, Linux)
- bash, zsh, or fish
- Write access to your shell config file