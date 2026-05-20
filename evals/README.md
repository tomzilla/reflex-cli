# Reflex CLI Evals

Automated tests to verify reflex-cli behaves correctly.

## Running

```bash
./evals/run.sh              # Run all evals
./evals/run.sh <eval-name>  # Run specific eval
```

## Eval List

| Eval | What it tests |
|------|---------------|
| `eval_alias_suggest` | Usage logs written correctly, frequency counted |
| `eval_script_family_detection` | Script executions tracked in scripts.log |
| `eval_reflex_list` | `reflex list` shows installed commands |
| `eval_reflex_help` | `reflex help <cmd>` shows usage |
| `eval_reflex_new_scaffolds` | `reflex new` creates scaffold with -h support |
| `eval_hook_logs_commands` | Hook logs commands in correct format |

## Adding Evals

Add a function to `run.sh`:

```bash
eval_my_test() {
    info "Testing my feature"
    # setup
    # assert
    pass "My test passed"
    # or
    fail "My test failed"
}
```

Then add `eval_my_test` to the `ALL_EVALS` array.

## Success Criteria

All evals must pass before merging. A failing eval means the feature is broken.