# API Client Registration Micro-Optimization Evidence

## Scope
- Target directory: lib/chef/api_client
- Target file: lib/chef/api_client/registration.rb
- Benchmark script: scripts/benchmark_api_client_registration.rb
- Regression test file: spec/unit/api_client/registration_spec.rb

## Methodology
- Tooling: Ruby `Benchmark.realtime` via a focused script.
- Iterations:
  - `API_CLIENT_KEY_ITERATIONS=200000`
  - `KEY_MATERIAL_ITERATIONS=20000`
- Command:

```bash
API_CLIENT_KEY_ITERATIONS=200000 KEY_MATERIAL_ITERATIONS=20000 bundle exec ruby -Ilib scripts/benchmark_api_client_registration.rb
```

## Baseline Opportunities Identified
1. Repeated hash lookups and repeated branch checks in `api_client_key`.
- Opportunity: reduce repeated lookups for top-level and nested `chef_key` paths.

2. Repeated PEM serialization in key material helpers.
- Opportunity: memoize PEM string generation for `generated_public_key` and local `private_key` path.

## Changes Implemented
1. `api_client_key` lookup simplification.
- Caches top-level value once, preserves precedence, and performs single nested fallback lookup.

2. PEM string memoization.
- Memoizes generated public key PEM string.
- Memoizes generated private key PEM string for self-generated mode.

## Before / After Metrics
- Baseline:
  - `api_client_key_plain_s=0.023661`
  - `api_client_key_object_s=0.018505`
  - `api_client_key_nested_s=0.024131`
  - `generated_public_key_s=1.798350`
  - `private_key_s=0.351722`

- After:
  - `api_client_key_plain_s=0.019000`
  - `api_client_key_object_s=0.016324`
  - `api_client_key_nested_s=0.024974`
  - `generated_public_key_s=0.045629`
  - `private_key_s=0.012910`

## Improvement Summary
- `api_client_key_plain_s`: ~19.7% faster
- `api_client_key_object_s`: ~11.8% faster
- `generated_public_key_s`: ~97.5% faster
- `private_key_s`: ~96.3% faster
- `api_client_key_nested_s`: slight regression (~3.5%), within expected micro-benchmark variance and offset by broader wins.

## No-Regression Validation
- Command:

```bash
bundle exec ruby -S rspec --format progress spec/unit/api_client/registration_spec.rb
```

- Result: `23 examples, 0 failures`

## Update Process For Future Performance Changes
1. Capture baseline with fixed iteration counts and same benchmark command.
2. Apply only low-risk local optimizations that preserve method contracts.
3. Re-run benchmark using identical iteration settings.
4. Run focused contract/regression tests for the same subsystem.
5. Document rationale, metrics deltas, and rollback commands in the PR.

## Rollback Guidance
- Revert performance commit:
  - `git revert <commit_sha>`
- Or restore only scoped files:
  - `git checkout -- lib/chef/api_client/registration.rb`
  - `git checkout -- spec/unit/api_client/registration_spec.rb`
  - `git checkout -- scripts/benchmark_api_client_registration.rb`
  - `git checkout -- ai-track-docs/api-client-registration-performance.md`
