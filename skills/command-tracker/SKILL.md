---
name: "command-tracker"
description: "Track CLI commands executed by the agent, identify patterns, and suggest aliases or shell functions to add to the host's shell configuration."
---

# Command Tracker

Observes and records CLI commands used by the agent, then identifies patterns that could become permanent shell aliases or functions on the host machine.

## Usage

```
/track                    # Analyze recent commands and suggest improvements
/track --top              # Show most-used commands
/track --patterns         # Find recurring patterns worth aliasing
/track --install          # Write suggested aliases to shell config
```

## How It Works

### Phase 1: Observation (Background Hook)

The `command-track.sh` hook fires on every Bash tool call. It logs:
- Timestamp
- Exit code
- Command (truncated to 200 chars)

Log files live at `~/.agent-cli/usage/commands-YYYY-MM-DD.log`, one per day.

### Phase 2: Analysis (`/track`)

Reads the usage logs (last 14 days by default), then:

1. **Count command frequency** — which commands appear most
2. **Find long commands** — repeated multi-part commands that could be functions
3. **Spot aliases** — short repeated patterns with the same structure
4. **Detect path patterns** — same file/directory accessed repeatedly

### Phase 3: Suggestion

Produces a report of patterns that warrant aliases/functions:

```
📊 Command Usage Analysis (14 days)

🔝 Most Used Commands:
  1. git status           — 47x
  2. grep -r             — 23x
  3. curl -sL            — 19x
  4. ls -la              — 18x

⚡ Alias Candidates:
  1. git st → git status (saves 7 chars × 47 = 329 chars)
  2. grepr → grep -r (saves 4 chars × 23 = 92 chars)

📦 Function Candidates:
  1. git log with color + graph — appears 12x with same flags
     → Suggest: add to ~/.gitconfig or zsh alias
  2. curl with -sL and json parsing — appears 8x
     → Suggest: shell function with jq built-in

💡 Recommended Additions:
  alias gs='git status'
  alias gl='git log --oneline --graph --decorate'
  # or for complex patterns:
  # function git-log-pretty() { git log --oneline --graph --decorate "$@"; }
```

### Phase 4: Adoption

The `/track --install` command writes aliases/functions to the host shell config:
- `~/.bashrc` (bash)
- `~/.zshrc` (zsh)
- `~/.config/fish/config.fish` (fish)

For more complex functions, writes to `~/.agent-cli/functions/` and sources from the main config.

## Commands

### `/track`

Analyze usage logs and show patterns with the highest ROI for aliasing.

### `/track --top N`

Show the top N most-used commands. Default: 10.

### `/track --patterns`

Show only patterns that exceed the frequency threshold (3+ uses).

### `/track --install`

Interactively prompt for each suggestion — confirm before writing. Writes to the appropriate shell config based on the host's current shell.

## Analysis Logic

### Pattern Detection

1. **Alias candidates**: Single-word commands with no flags, used 5+ times
2. **Flag pattern candidates**: Same command with same flags used 3+ times
3. **Chain pattern candidates**: Commands frequently chained with `&&` or `||`
4. **Path pattern candidates**: Same file/directory accessed 3+ times in different commands

### Scoring

Each pattern scored on:
- **Frequency**: How many times it appears (0-3)
- **Savings**: Characters saved × frequency (0-3)
- **Complexity**: Multi-part commands score higher (0-3)

Total score ≥ 5 → recommended for aliasing.

## Log Format

```
TIMESTAMP|EXIT_CODE|COMMAND
```

Example:
```
1716230400|0|git status
1716230500|1|grep -r "pattern" src/
1716230600|0|curl -sL https://api.example.com/health
```

## Tips

- Run `/track --top 20` weekly to catch new patterns
- Complex multi-step commands often make the best functions
- Consider shell completion for function arguments
- Group related aliases by concern in your shell config