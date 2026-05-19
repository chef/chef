# Logging

## Structured Logging Acceptance

- Structured logs added: yes
- Format fields: `op`, `status`, `elapsed_ms`
- Instrumented path: `spellcheck:config_check` in `tasks/spellcheck.rb`

## Log Schema

Each structured log line uses this shape:

```text
op=<operation_name> status=<ok|error> elapsed_ms=<milliseconds>
```

Example:

```text
op=spellcheck_config_check status=ok elapsed_ms=4.109
```

## Where Logs Are Emitted

- File: `tasks/spellcheck.rb`
- Task: `spellcheck:config_check`
- Emission points:
  - Missing config file -> `status=error`
  - Invalid JSON -> `status=error`
  - Invalid top-level type -> `status=error`
  - Successful validation -> `status=ok`

## How To View Logs

Show all structured spellcheck logs:

```bash
cd /Users/rchawda/github.com/chef/chef
bundle exec rake spellcheck 2>&1 | rg "op=spellcheck_"
```

Show only failures:

```bash
cd /Users/rchawda/github.com/chef/chef
bundle exec rake spellcheck 2>&1 | rg "op=spellcheck_.*status=error"
```

## Notes

- `elapsed_ms` is computed with a monotonic clock (`Process::CLOCK_MONOTONIC`) to avoid wall-clock skew.
- This logging is intentionally lightweight and line-oriented for local debugging and CI log scanning.

## Toggle

Structured logging for `spellcheck:config_check` can be toggled with an environment variable:

- ON (default): unset `SPELLCHECK_STRUCTURED_LOGS` or set it to any value other than `0`
- OFF: set `SPELLCHECK_STRUCTURED_LOGS=0`

Examples:

```bash
# Default ON
bundle exec rake spellcheck

# Explicit OFF
SPELLCHECK_STRUCTURED_LOGS=0 bundle exec rake spellcheck
```
