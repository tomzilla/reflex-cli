# Shell Configuration Guide

How aliases and functions are written to your shell config.

## Supported Shells

| Shell | Config File |
|-------|-------------|
| bash | `~/.bashrc` |
| zsh | `~/.zshrc` |
| fish | `~/.config/fish/config.fish` |

## Alias Format

```bash
# Simple alias
alias gs='git status'

# With arguments (pass-through)
alias grep='grep --color=auto'
```

## Function Format

```bash
# For complex commands with arguments
function git-log-pretty() {
    git log --oneline --graph --decorate "$@"
}

# With description comment
# Useful for: git log with color + graph
git_log_pretty() {
    git log --oneline --graph --decorate "$@"
}
```

## Install Script Behavior

When `/track --install` runs:

1. Detect current shell via `$SHELL`
2. Read existing config to avoid duplicates
3. Write new aliases to the appropriate file
4. For functions, write to `~/.agent-cli/functions/` and add a source line to the main config

### Function file structure

```
~/.agent-cli/functions/
├── git-commands.sh
├── docker-commands.sh
└── custom.sh
```

Main config gets:
```bash
# Agent CLI functions
for f in ~/.agent-cli/functions/*.sh; do
    source "$f"
done
```

## Duplicate Prevention

Before writing, check:
- `alias | grep <name>` — skip if alias already exists
- `type <name>` — skip if command already defined

## Edge Cases

- If config file doesn't exist, create it
- If no write permission, report error and suggest `sudo` approach
- For fish, use `func.save` approach or direct config append