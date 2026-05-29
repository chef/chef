# Target IO Resilience Ops Runbook (2026-05-29)

## Scope

- Folder: `lib/chef/target_io/`
- Pattern: shared timeout and backoff helper in `TargetIO::Resilience`

## External Call Paths and Previous Failure Behavior

- `TargetIO::TrainCompat::Dir.entries`

- External call: remote `ls -1a` via transport `run_command`
- Previous behavior: one timeout or transient exception failed the call immediately.

- `TargetIO::TrainCompat::Dir.glob`

- External call: remote shell glob expansion via transport `run_command`
- Previous behavior: one timeout or transient exception failed the call immediately.

- `TargetIO::TrainCompat::FileUtils.cp` (and sibling fileutils commands)

- External call: remote shell command execution via transport `run_command`
- Previous behavior: one timeout or transient exception failed the operation immediately.

## Resilience Helper

- Helper: `TargetIO::Resilience.with_timeout_and_backoff(operation:)`
- Applied at: `TargetIO::Support#run_command`
- Effect: all TargetIO train command executions now use the same timeout/retry/backoff behavior.

## Tuning Parameters

- `CHEF_TARGET_IO_RESILIENCE_ENABLED`
- Default: `true`
- Values: `true|false|1|0|yes|no|on|off`

- `CHEF_TARGET_IO_RESILIENCE_MAX_ATTEMPTS`
- Default: `3`
- Meaning: total attempts before raising the last error.

- `CHEF_TARGET_IO_RESILIENCE_TIMEOUT_SECONDS`
- Default: `10.0`
- Meaning: timeout per attempt.

- `CHEF_TARGET_IO_RESILIENCE_BACKOFF_BASE_SECONDS`
- Default: `0.25`
- Meaning: base exponential backoff delay.

- `CHEF_TARGET_IO_RESILIENCE_BACKOFF_MAX_SECONDS`
- Default: `2.0`
- Meaning: upper bound for retry delay.

## Escalation Steps

1. Identify repeated warnings matching: `TargetIO resilience retry for`.
2. Capture failing command and error class from logs.
3. Increase timeout/backoff if remote links are latent.
4. If failures persist across all attempts, escalate to transport/network triage with captured command and target host details.

## Rollback

- Fast rollback (runtime): disable helper.
  - `export CHEF_TARGET_IO_RESILIENCE_ENABLED=false`
- Code rollback:
  - `git revert <commit-sha>`
