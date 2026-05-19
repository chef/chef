# BACKLOG EX12

## 1) Expand Structured Logging Across Spellcheck Tasks

- Add `op`, `status`, and `elapsed_ms` logs to `spellcheck:cspell_check` and `spellcheck:run`.
- Keep current task behavior and failure messages unchanged.
- Update logging documentation with examples for all spellcheck task paths.

## 2) Improve Local CI Fallback Script Parity

- Extend `scripts/run_local_ci_tests.sh` with optional flags for skipping bundle install and fixture-only setup.
- Keep default mode behavior unchanged (`quick` and `full`).
- Document all options in build/test docs with copy-paste commands.

## 3) Pin Git-Sourced Dependencies by Commit Ref

- Replace floating branch-only Git gem declarations with explicit `ref` pins for `ohai`, `cheffish`, and `rest-client`.
- Ensure lockfile remains reproducible after update.
- Record update procedure and pin values in dependency notes.

## 4) Add Lightweight Secret-Hygiene Validation

- Add a script/rake task to detect likely secrets in tracked files.
- Exclude noisy paths (for example, `vendor/`) to reduce false positives.
- Return non-zero exit code when high-confidence secret patterns are found.

## 5) Add Perf Guardrail Check for Spellcheck Config Path

- Extend benchmark script to support threshold checks (mean/p95).
- Fail fast when threshold is exceeded.
- Document baseline threshold values and rerun procedure.
