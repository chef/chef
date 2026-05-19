# Spellcheck Task Module: Extending Guide

This guide covers safe, low-risk extensions to the spellcheck task module in `tasks/spellcheck.rb`.

## Scope

The module defines three concerns:

- `spellcheck:cspell_check`: verifies the `cspell` CLI is available.
- `spellcheck:config_check`: validates readability and JSON format of `cspell.json`.
- `spellcheck:run`: executes `cspell lint --no-progress "**/*"`.

The top-level `spellcheck` task maps to `spellcheck:run`.

## Safe Extension Rules

1. Preserve current task names and dependency order unless intentionally changing CLI behavior.
2. Keep abort messages stable when possible; tests rely on these strings.
3. Prefer fast-fail checks before shelling out.
4. Keep configuration filename usage centralized via `CSPELL_CONFIG_FILE`.

## Common Tiny Extensions

- Add one more config sanity check in `config_check` (for example, required JSON key presence).
- Add optional environment-driven include/exclude globs in `run` while keeping defaults unchanged.
- Improve CLI availability detection in `cspell_check` without altering user-facing failure text.

## Minimal Test Strategy

Tests live in `spec/unit/tasks/spellcheck_task_spec.rb` and should remain deterministic:

1. Missing config file aborts with not-found message.
2. Invalid JSON aborts with parse-failure message.
3. Valid JSON passes.

When adding behavior, add one focused example per branch and keep filesystem effects inside the temporary test directory created by the `around` hook.

## Commands

```bash
cd /Users/rchawda/github.com/chef/chef
bundle exec rspec spec/unit/tasks/spellcheck_task_spec.rb
bundle exec rake spellcheck
```
