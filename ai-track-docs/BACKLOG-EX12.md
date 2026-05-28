# Epic EX12: Walk Follow-On Hardening Backlog

## Epic Goal

Translate prior Walk findings into small, reviewable follow-on issues that improve reliability, reproducibility, and observability.

## Epic Scope

- In scope: spellcheck task logging/perf checks, local CI helper parity, dependency pinning guidance, and lightweight secret-hygiene checks.
- Out of scope: broad architecture refactors, vendor/submodule updates, and multi-team workflow redesign.

## Epic Acceptance Criteria

- 3-5 actionable issues are defined and each is deliverable in one PR.
- Every issue includes explicit acceptance criteria and local verification.
- Every issue links to concrete code/documentation paths.
- Cross-issue dependencies are documented.

## Issue 1: Structured Logging in Spellcheck Tasks

### Scope

Add structured lifecycle logging fields for spellcheck task entry/exit while preserving current behavior.

### Code Paths

- tasks/spellcheck.rb
- ai-track-docs/logging.md

### Acceptance Criteria

- spellcheck:cspell_check and spellcheck:run log op, status, and elapsed_ms on completion paths.
- Existing failures and exit codes remain unchanged.
- Logging examples are documented for success and failure cases.

### Verification Steps

1. bundle exec rake spellcheck:cspell_check
2. bundle exec rake spellcheck:run
3. Confirm expected structured fields are emitted in output.

### Evidence to Capture

- Before/after sample output lines containing op/status/elapsed_ms.
- Confirmation that task failure text is unchanged.

### Rollback

- Revert the logging-only commit for tasks/spellcheck.rb.
- Re-run spellcheck task commands and confirm old output format is restored.

### Dependencies

- None.

## Issue 2: Local CI Script Parity Improvements

### Scope

Add optional flags to local CI fallback to better mirror CI troubleshooting modes without changing defaults.

### Code Paths

- scripts/run_local_ci_tests.sh
- ai-track-docs/build-test.md

### Acceptance Criteria

- New optional flags support skipping bundle install and fixture-only setup.
- quick and full default behavior remains unchanged.
- Build/test docs include copy-paste examples for each new flag.

### Verification Steps

1. bash scripts/run_local_ci_tests.sh quick
2. bash scripts/run_local_ci_tests.sh full
3. Run script with each new flag and verify intended step is skipped.

### Evidence to Capture

- Script output showing each mode/flag path taken.
- Short table in docs mapping flags to behavior.

### Rollback

- Revert script and docs commits.
- Re-run quick/full and confirm original behavior.

### Dependencies

- None.

## Issue 3: Pin Git-Sourced Gems by Ref

### Scope

Replace branch-only git gem declarations with explicit refs and document update workflow.

### Code Paths

- Gemfile
- Gemfile.lock
- ai-track-docs/dependency-notes.md

### Acceptance Criteria

- ohai, cheffish, and rest-client git gems use explicit ref values.
- Bundle resolution is reproducible from a clean checkout.
- Dependency notes document pin update procedure and ownership.

### Verification Steps

1. bundle install
2. bundle exec ruby -e "puts 'bundle-ok'"
3. Confirm Gemfile and lockfile reflect pinned refs.

### Evidence to Capture

- Diff snippets for Gemfile/Gemfile.lock pin changes.
- Successful bundle install output from clean state.

### Rollback

- Revert Gemfile and lockfile pin commits.
- Re-run bundle install to confirm prior state restoration.

### Dependencies

- Preferred before Issue 2 and Issue 5 to reduce flaky dependency drift in local validation.

## Issue 4: Lightweight Secret-Hygiene Gate for Local Changes

### Scope

Add a lightweight developer-facing secret scan command for tracked files with low-noise defaults.

### Code Paths

- scripts/ (new scanner helper)
- tasks/ (new or updated rake hook)
- ai-track-docs/security.md

### Acceptance Criteria

- A local command scans tracked files and exits non-zero on high-confidence matches.
- Noisy paths (including vendor/) are excluded by default.
- Docs include bypass/escalation guidance for false positives.

### Verification Steps

1. Run the new local secret-hygiene command on current tree.
2. Validate non-zero exit behavior with a test fixture pattern.
3. Validate exclusion behavior for vendor/ paths.

### Evidence to Capture

- Example pass/fail command output.
- False-positive handling guidance in docs.

### Rollback

- Revert script/task/doc commits.
- Confirm no local secret-hygiene command is wired into tasks.

### Dependencies

- None.

## Issue 5: Perf Guardrail for Spellcheck Config Check

### Scope

Add optional threshold enforcement to spellcheck config benchmark and document baseline/refresh process.

### Code Paths

- scripts/spellcheck_config_check_benchmark.rb
- ai-track-docs/perf-baseline.md
- ai-track-docs/build-test.md

### Acceptance Criteria

- Benchmark supports configurable mean_ms and p95_ms thresholds.
- Command exits non-zero when thresholds are exceeded.
- Perf baseline doc defines threshold values and rerun procedure.

### Verification Steps

1. bundle exec ruby scripts/spellcheck_config_check_benchmark.rb
2. Run with a permissive threshold and confirm pass.
3. Run with an intentionally strict threshold and confirm fail.

### Evidence to Capture

- benchmark=spellcheck:config_check output including mean_ms and p95_ms.
- Pass/fail examples with threshold inputs.

### Rollback

- Revert benchmark/doc commits.
- Re-run benchmark and confirm threshold flags are absent.

### Dependencies

- Depends on Issue 3 for consistent dependency state across environments.

## Dependency Summary

- Issue 3 -> Issue 5 (required)
- Issue 3 -> Issue 2 (recommended)
- Issue 1, Issue 2, and Issue 4 can run independently.

## Tracker Mapping

If issue tracker access is available, create:

- Epic: Epic EX12 - Walk Follow-On Hardening
- Child issues: EX12-1 through EX12-5 mapped to the five items above

If tracker access is unavailable, this document is the committed backlog source of truth.
