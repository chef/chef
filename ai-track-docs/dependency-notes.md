# Dependency Notes

## Scope

This note documents critical dependencies and proposes minimal, low-risk pinning/constraints that avoid major upgrades.

## Critical Dependencies

1. Runtime and toolchain

- Ruby runtime: CI currently runs Ruby 3.4 in workflow matrices.
- Bundler lock state: Gemfile.lock is authoritative for reproducible local and CI installs.

1. Git-sourced gems in Gemfile (high change risk)

- ohai from chef/ohai main branch.
- cheffish from chef/cheffish main branch.
- rest-client from chef fork branch jfm/ucrt_update1.

Current lockfile revisions:

- ohai: 5b34b044c1c85517f9eaa09b8f470991f8591a4f
- cheffish: 5095f5699a3a88c611caca393c4d1710a5625b4f
- rest-client: 4725c8b5ae09b3f6b968831beae27503f1261ea9

1. Security and compatibility-sensitive gems (already constrained)

- uri >= 1.0.4 and < 1.2.0
- ffi >= 1.15.5 and < 1.18.0
- mixlib-shellout >= 3.3.8 and < 3.5.0
- inspec-core ~> 7.0.107
- train-core ~> 3.13, >= 3.13.4

1. Spellcheck tool dependency

- cspell CLI is required by tasks/spellcheck.rb and installed outside Bundler (global npm install path).

## Minimal Pinning and Constraint Proposals

1. Keep existing gem upper bounds as-is

- Do not relax upper bounds in chef.gemspec unless required by a targeted fix.

1. Stabilize git-sourced gems with revision pins in Gemfile

- For low-risk reproducibility, prefer ref pins to currently locked commits for ohai, cheffish, and rest-client.
- This avoids accidental drift from upstream main/branch movement while preserving current behavior.

Suggested shape (no major version change):

- gem "ohai", git: "<https://github.com/chef/ohai.git>", ref: "5b34b044c1c85517f9eaa09b8f470991f8591a4f"
- gem "cheffish", git: "<https://github.com/chef/cheffish.git>", ref: "5095f5699a3a88c611caca393c4d1710a5625b4f"
- gem "rest-client", git: "<https://github.com/chef/rest-client>", ref: "4725c8b5ae09b3f6b968831beae27503f1261ea9"

1. Keep cspell deterministic for local contributors

- Add documentation guidance to use an explicit cspell version (for example, npm install -g <cspell@8.x>) and update intentionally.
- This is documentation-level pinning; no runtime dependency impact.

1. Keep development/test gems conservative

- Prefer minor-range constraints for frequently changing tooling gems only when churn is observed.
- Avoid broad tightening until there is a concrete breakage signal.

## Verification Checklist

1. Install/update dependencies

```bash
cd /Users/rchawda/github.com/chef/chef
bundle install
```

1. Confirm git dependency revisions in lockfile

```bash
rg "^GIT|^  remote:|^  revision:" Gemfile.lock
```

1. Run low-risk module tests and unit sanity

```bash
bundle exec rspec spec/unit/tasks/spellcheck_task_spec.rb
bundle exec rake spec:unit
```

1. Validate spellcheck tool availability

```bash
bundle exec rake spellcheck
```

## Notes

- Proposals above are intentionally minimal and avoid major upgrades.
- Apply one constraint change at a time and re-run unit/functional CI to isolate regressions.

## Security Notes (Secret Hygiene)

Critical secret surfaces in this repository/workflow:

- Local env/config files (`.env*`, `.netrc`, `.npmrc`) that may contain tokens.
- Generated kitchen artifacts that can carry credentials (`kitchen-tests/hab_token`, `kitchen-tests/gha-key.tar.gz`).
- CI/runtime env vars such as `HAB_AUTH_TOKEN` and other credential-like values.

Minimal constraints (no major changes):

1. Keep secrets out of source control

- Ensure common secret file patterns are ignored in `.gitignore`.
- Keep generated token/key artifacts ignored by default.

1. Prefer environment-provided credentials

- Continue using environment variables and secret managers in CI.
- Avoid adding new static keys/tokens in docs, tests, and YAML defaults.

1. Log hygiene

- Do not echo full credential values in scripts.
- Redact or truncate sensitive values when debug output is required.

Quick checks:

```bash
cd /Users/rchawda/github.com/chef/chef
git status --short
rg -n "(token|secret|password|private[_-]?key|api[_-]?key)" kitchen-tests .github .buildkite .expeditor --glob '!vendor/**'
```

## Dependency Upgrade Exercise (2026-05-28)

### Goal

- Find and apply one safe minor dependency upgrade with validation evidence.

### What Was Checked

- Strict outdated checks were run with Bundler in first-party bundles:
	- `/chef-utils`
	- `/chef-config`
	- `/chef` (root; limited by git-sourced dependency fetch behavior)
	- `/kitchen-tests` (dependency solver conflict with `inspec = 7.0.95` and `chef`'s `inspec-core ~> 7.0.107` requirement)

### Result

- No actionable minor upgrade was available in tracked lockfiles for low-risk, reviewable scope.
- Candidate updates detected in strict mode were patch-level rspec family updates, but lockfiles were already at those versions in source control.
- Root bundle outdated checks were not reliable for selection due repeated git-source fetch behavior in this environment.

### Fallback Applied

- Followed troubleshooting guidance: documented current state and verified patch-level status.
- No dependency lockfile change was committed.

### Validation Evidence

- Full chef-utils test suite run:
	- Command: `bundle exec rake spec`
	- Result: `6921 examples, 0 failures`

### Rollback

- No repository dependency change was applied, so rollback is a no-op.
- If a future dependency change is applied, rollback command pattern:
	- `git revert <commit_sha>`
	- or re-pin prior version and run `bundle install`.
