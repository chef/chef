# Security Scanning

## Overview

This document describes the secret/credential scanning process for the Chef Infra repository.

## Scanners in Use

### 1. TruffleHog (CI — shared pipeline)

- **Where:** `.github/workflows/ci-main-pull-request-stub.yml`
- **Trigger:** Every PR and push to `main` / `release/**`
- **Config:** `perform-trufflehog-scan: true` (managed by `chef/common-github-actions`)
- **Scope:** Full git history scan for high-entropy strings and known secret patterns

### 2. Gitleaks (CI — lint workflow)

- **Where:** `.github/workflows/lint.yml` (`secret-scan` job)
- **Trigger:** Every PR and push to `main`
- **Config:** `.gitleaks.toml` at repo root
- **Scope:** Commits in the PR range only (`--log-opts "origin/main..HEAD"`)
- **Tool:** `gitleaks` CLI v8.24.3, installed directly from GitHub Releases (MPL-2.0; no org license required)
- **Report:** JSON artifact uploaded as `gitleaks-report` on every run (including failures)

### 3. GitHub Advanced Security (GHAS)

- **Where:** Repository settings (GitHub native)
- **Scope:** Push-protection and secret-alert rules for common token patterns (API keys, tokens)

## Configuration

The gitleaks configuration lives at [.gitleaks.toml](../.gitleaks.toml).
Update it when:
- A new test fixture is added that contains credential-like strings
- A false-positive must be suppressed with a justification comment

## Known Findings — Justified Ignores

The following paths contain intentional test fixtures with credential-like content.
They are allowlisted in `.gitleaks.toml`. All entries include an inline justification comment.

| Path | Pattern | Justification |
|------|---------|---------------|
| `spec/data/ssl/` | RSA private keys (`.key`, `.pem`) | Dummy self-signed certs for HTTP authenticator RSpec tests. Not trusted in any production system. |
| `spec/data/cookbooks/openldap/` | Plaintext passwords (`yougotit`, `forsure`) | Fictional test cookbook attribute defaults. Never deployed. |
| `spec/integration/client/` | Inline RSA signing key PEM | Hard-coded test key for deterministic HTTP signing integration tests. |
| `spec/unit/server_api_spec.rb` | `SIGNING_KEY_DOT_PEM` constant | Test-only RSA stub used to configure `Chef::Config` in unit tests. |
| `spec/unit/http/authenticator_spec.rb` | Certificate file reference | Test verifying certificate object behavior; no real key material stored. |

## Adding a New Justified Ignore

1. Add the path or regex to `.gitleaks.toml` under `[allowlist]`.
2. Include a comment explaining why it is safe.
3. Update the Known Findings table above.
4. Get the change reviewed before merging.

## Running the Scan Locally

```bash
# Install gitleaks (macOS)
brew install gitleaks
# or pin to the same version as CI:
# curl -sSfL https://github.com/gitleaks/gitleaks/releases/download/v8.24.3/gitleaks_8.24.3_darwin_arm64.tar.gz | tar -xz -C /usr/local/bin gitleaks

# Run against the current working tree
gitleaks detect --config .gitleaks.toml --source . --verbose

# Run against a specific commit range (mirrors CI behavior)
gitleaks detect --config .gitleaks.toml --source . --log-opts "origin/main..HEAD" --verbose
```

## Rollback

- To disable the gitleaks CI job: remove or comment out the `secret-scan` job in `.github/workflows/lint.yml`.
- To revert the `.gitleaks.toml`: `git revert <commit_sha>` or delete the file (gitleaks-action uses built-in rules when no config is present).
- TruffleHog is managed centrally via `chef/common-github-actions`; changes there require a PR to that shared repository.
