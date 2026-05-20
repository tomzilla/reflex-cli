---
name: "reflex"
description: "Track agent CLI commands, detect script patterns, and build a persistent command toolkit accessible as reflex <cmd>."
---

# Reflex CLI

Tracks CLI commands the agent uses, detects when you're building a reusable tool (especially Python scripts), and creates a persistent command hierarchy accessible as `reflex <cmd>` on the host machine.

## Architecture

```
~/.reflex-cli/
├── reflex              ← master CLI (the "host cli")
├── bin/                ← installed commands (parse, build, deploy, etc.)
│   └── parse.py
└── usage/
    ├── commands-YYYY-MM-DD.log
    └── scripts.log

Agent shell → reflex parse → ~/.reflex-cli/bin/parse.py
```

## Core Concept

When the agent repeatedly writes a Python script with variations — `~/tmp/parse_v1.py`, `~/tmp/text_filter.py`, `~/tmp/extract_lines.py` — Reflex detects this "script family" and consolidates it into one generic tool at `~/.reflex-cli/bin/parse`.

Once installed: agent calls `reflex parse file.txt` instead of `python ~/tmp/scratch_parse.py`.

## Commands

### `/reflex`
Analyze usage logs (last 14 days) and show all patterns with suggestions.

### `/reflex --top N`
Show top N most-used commands.

### `/reflex --patterns`
Show only recurring patterns (3+ uses), including script families.

### `/reflex --install`
Write confirmed aliases/shell functions to shell config. **Do not overwrite existing bin/ scripts.**

### `/reflex build <name>`
Scaffold a new reflex command. Agent provides the implementation.

```
/reflex build parse
→ Creates ~/.reflex-cli/bin/parse (or parse.py if Python)
→ Agent implements it
→ Call with: reflex parse --help
```

## Use Cases

### 1. Script family consolidation (primary use case)

The agent writes different Python scripts repeatedly:

```
~/tmp/parse_fast.py     — read file, filter lines, output
~/tmp/text_tool.py      — read file, split on comma, output
~/tmp/extract.py        — read file, grep for pattern, output
```

All do text parsing with slight differences. Reflex detects:
- 3+ Python scripts with similar purpose (file → filter → output)
- Different names, different slight variations
- Same input/output pattern

Analysis:
```
📦 Script Family Detected: text parsing
  ~/tmp/parse_fast.py   — filter lines matching pattern
  ~/tmp/text_tool.py    — split on delimiter
  ~/tmp/extract.py      — extract matching lines

  → Consolidated into: reflex parse
  → Available flags: --filter, --delimiter, --match

Run /reflex build parse to implement.
```

### 2. Single script used repeatedly

```
~/tmp/deploy.sh — run 3x
```
Suggests: `reflex add ~/tmp/deploy.sh` → `reflex deploy`

### 3. One-liner patterns → shell aliases

```
grep -r "TODO" src/ --include="*.ts"  — 10x
```
Suggests: `alias greptodo='grep -r "TODO" src/ --include="*.ts"'`

### 4. Complex command chains → functions

```
git stash && git pull --rebase && git stash pop  — 5x
```
Suggests: `git-sync` shell function

### 5. Path shortcuts → aliases

```
cd ~/projects/very-long-directory/src/api  — 4x
```
Suggests: `alias api='cd ~/projects/very-long-directory/src/api'`

## Script Detection Logic

### Hook tracks:
- All Bash commands → `~/.reflex-cli/usage/commands-YYYY-MM-DD.log`
- Python/script executions → `~/.reflex-cli/usage/scripts.log`

### Pattern detection:
1. **Same file, 2+ executions** → candidate for `reflex add`
2. **Script family** (same purpose, different names, 3+ scripts in 30 days) → candidate for `reflex build`
3. **Flag patterns** (same command + same flags, 3+ uses) → alias candidate
4. **Chain patterns** (`&&` / `||`) → function candidate

### Script family scoring:
- Same file type (.py, .sh)
- Similar input pattern (file argument)
- Similar output pattern (stdout)
- Different names (variations instead of exact repeats)

Score ≥ 6 → suggest `reflex build <name>` to consolidate.

## Building a New Command

When `/reflex build parse` is called:

1. Create `~/.reflex-cli/bin/parse.py` with argparse skeleton
2. Include `# description:` comment for `reflex list`
3. Implement the command with proper `-h`/`--help`
4. Agent writes the implementation
5. Test with `reflex parse -h`

### Implementation template:

```python
#!/usr/bin/env python3
# description: Parse and transform text files
import argparse

def main():
    parser = argparse.ArgumentParser(
        description='Parse and transform text files. Use when: you need to filter, split, or extract from a text file.',
        epilog='Examples:\n  reflex parse --filter=error app.log\n  reflex parse --delimiter=, data.csv'
    )
    parser.add_argument('input', nargs='?', help='Input file (default: stdin)')
    parser.add_argument('--filter', '-f', metavar='PATTERN', help='Filter lines matching pattern')
    parser.add_argument('--delimiter', '-d', metavar='CHAR', help='Split on delimiter')
    parser.add_argument('--match', '-m', metavar='REGEX', help='Extract matches from regex')
    parser.add_argument('--invert', '-v', action='store_true', help='Invert match')
    args = parser.parse_args()

    # TODO: implement

if __name__ == '__main__':
    main()
```

## `-h` / `--help` Standard

Every reflex command must implement `-h` / `--help` that shows:
1. One-line description
2. Usage line
3. All flags with examples
4. "Use when:" trigger conditions

Built-in reflex commands (`list`, `add`, `remove`, `new`, `help`) all have `-h` handling in the `reflex` wrapper script.

## Log Format

```
commands-YYYY-MM-DD.log:
TIMESTAMP|EXIT_CODE|COMMAND

scripts.log:
TIMESTAMP|EXIT_CODE|FULL_PATH_TO_SCRIPT
```

## Shell Integration

Install `reflex` to PATH:
```bash
cp reflex ~/.local/bin/reflex
chmod +x ~/.local/bin/reflex
# or: reflex new reflex (installs the wrapper itself)
```

Then agent calls `reflex parse file.txt` and it runs `~/.reflex-cli/bin/parse.py`.

## Tips

- Run `/reflex --top 20` weekly to catch new script families
- The script family detection is the highest-value feature — watch for it
- `reflex list` shows all installed commands with descriptions
- Use `reflex help <cmd>` to see a command's usage
- Group related scripts in bin/ — naming conventions are up to the agent