# Agent CLI

> Turn your agent's command patterns into permanent shell aliases.

An agent plugin that observes CLI commands your agent executes, identifies recurring patterns, and suggests — then installs — shell aliases and functions to your host machine.

## What It Does

1. **Tracks** every Bash command your agent runs (via a lightweight hook)
2. **Analyzes** the last 14 days of usage to find patterns
3. **Suggests** aliases and functions with the highest ROI
4. **Installs** confirmed suggestions to your shell config (`~/.bashrc`, `~/.zshrc`, or fish)

## Commands

| Command | Description |
|---------|-------------|
| `/track` | Analyze recent commands, show all suggestions |
| `/track --top 20` | Show top 20 most-used commands |
| `/track --patterns` | Show only patterns (3+ uses) |
| `/track --install` | Write confirmed aliases to shell config |

## Example Session

```
> /track

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

Run /track --install to write these to your shell config.
```

## Install

```bash
# Clone into your agent's skills directory
git clone https://github.com/your/agent-cli ~/path/to/agent-cli

# Configure hook in your agent's settings.json
```

## How It Works

```
Command executed → hook fires → logs timestamp + command + exit code
                                    ↓
                            Rolling 14-day log files
                                    ↓
                    /track reads and analyzes patterns
                                    ↓
                    Suggestions generated (score ≥ 5)
                                    ↓
                    /track --install writes to shell config
```

## Log Location

```
~/.agent-cli/usage/commands-YYYY-MM-DD.log
```

Format: `TIMESTAMP|EXIT_CODE|COMMAND`

## Requirements

- Unix-like system (macOS, Linux)
- bash, zsh, or fish
- Write access to your shell config file