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

## Flag Lifecycle: SPELLCHECK_STRUCTURED_LOGS

### Creation

- Flag name: `SPELLCHECK_STRUCTURED_LOGS`
- Defined in: `tasks/spellcheck.rb`
- Purpose: allow low-risk enable/disable of structured log output for `spellcheck:config_check`

### Default State

- Default is ON.
- Behavior rule: `ENV.fetch("SPELLCHECK_STRUCTURED_LOGS", "1") != "0"`

### Enable / Disable

Enable (explicit ON):

```bash
cd /Users/rchawda/github.com/chef/chef
SPELLCHECK_STRUCTURED_LOGS=1 bundle exec rake spellcheck:config_check
```

Disable (OFF):

```bash
cd /Users/rchawda/github.com/chef/chef
SPELLCHECK_STRUCTURED_LOGS=0 bundle exec rake spellcheck:config_check
```

### Validation Strategy (ON and OFF)

Local contract checks:

```bash
cd /Users/rchawda/github.com/chef/chef
SPELLCHECK_STRUCTURED_LOGS=1 bundle exec rspec spec/unit/tasks/spellcheck_task_spec.rb
SPELLCHECK_STRUCTURED_LOGS=0 bundle exec rspec spec/unit/tasks/spellcheck_task_spec.rb
```

CI contract checks:

- Workflow: `.github/workflows/lint.yml`
- Job: `spellcheck-flag-modes`
- Matrix modes:
  - ON: `SPELLCHECK_STRUCTURED_LOGS=1`
  - OFF: `SPELLCHECK_STRUCTURED_LOGS=0`

### Removal Criteria

Remove this flag only when one of the following is true:

- structured logging behavior is permanently fixed with no planned fallback mode, and
- at least one full release cycle has run with ON behavior and no rollback need.

### Rollback

- Operational rollback: set `SPELLCHECK_STRUCTURED_LOGS=0`.
- Code rollback: revert flag-mode workflow job and lifecycle docs if policy changes.

---

## Cookbook Upload Instrumentation (ex9)

### Instrumented Path

- File: `lib/chef/cookbook_uploader.rb`
- Method: `Chef::CookbookUploader#upload_cookbooks`
- Emission point: just before `Chef::Log.info("Upload complete!")` on successful completion

### Upload Log Schema

```text
op=cookbook_upload status=ok cookbooks=<count> elapsed_ms=<milliseconds>
```

Example (from local demo run):

```text
[2026-05-28T19:53:15+05:30] INFO: op=cookbook_upload status=ok cookbooks=1 elapsed_ms=0.446
[2026-05-28T19:53:15+05:30] INFO: Upload complete!
```

The `elapsed_ms` covers the full `upload_cookbooks` span: syntax check, sandbox creation,
file streaming, and cookbook manifest commit.

### Where To View In Production / Staging

Any surface that invokes `knife cookbook upload` or the `Chef::CookbookUploader` at `:info`
log level will emit this line. Common entry points:

| Surface | Command / config |
| --- | --- |
| knife CLI | `knife cookbook upload mycookbook --log-level info` |
| chef-client convergence | `chef-client -l info` when upload is triggered during run |
| CI pipelines | any `bundle exec knife cookbook upload` step with `LOG_LEVEL=info` |
| Chef Automate | stream chef-client STDOUT; filter on `op=cookbook_upload` |

Filter example (local / CI log):

```bash
knife cookbook upload mycookbook 2>&1 | grep "op=cookbook_upload"
```

### Upload Notes

- Timing uses `Process::CLOCK_MONOTONIC` — immune to wall-clock adjustments during upload.
- Only emitted on the **success path**; a future exercise can add `status=error` on exception.
- The `cookbooks` counter reflects the number of cookbooks passed to the uploader in one batch.

Examples:

```bash
# Default ON
bundle exec rake spellcheck

# Explicit OFF
SPELLCHECK_STRUCTURED_LOGS=0 bundle exec rake spellcheck
```
