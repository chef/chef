# API Client Registration Boundary Validation Update

## Scope
- API folder: lib/chef/api_client
- Interface boundary: Chef::ApiClient::Registration
- Primary files:
  - lib/chef/api_client/registration.rb
  - spec/unit/api_client/registration_spec.rb

## Sweep Findings (TODOs, Validations, Edge Cases)
1. No TODO/FIXME markers were found in the scoped API files.
2. Edge case gap: server-generated mode accepted responses with missing private key and could proceed to key write path.
3. Coverage gap: no direct contract assertion that non-409 create failures must not fall back to update.
4. Coverage gap: no explicit contract assertion for retry override behavior via Chef::Config[:client_registration_retries].
5. Coverage gap: no explicit helper-level assertion for chef_key.private_key extraction fallback.

## Changes and Rationale
1. Added fail-fast validation in registration run flow for missing server-generated private key.
- File: lib/chef/api_client/registration.rb
- Rationale: prevents silent invalid local key state when remote response shape is incomplete.

2. Strengthened contract tests for non-409 create failures.
- File: spec/unit/api_client/registration_spec.rb
- Rationale: enforces interface contract that only 409 triggers update fallback.

3. Strengthened contract tests for retry override and no-write-on-failure side effect.
- File: spec/unit/api_client/registration_spec.rb
- Rationale: protects boundary behavior when operators tune retry config.

4. Added helper-level contract coverage for chef_key private_key fallback and mkdir permission error mapping.
- File: spec/unit/api_client/registration_spec.rb
- Rationale: validates payload normalization and filesystem error translation at interface boundaries.

## Validation Process For Future Boundary Changes
1. Identify boundary method and expected contract (inputs, fallback behavior, side effects).
2. Add tests for:
- accepted/expected response shapes
- malformed/missing-field response shapes
- non-happy-path error propagation
- side-effect boundaries (for example: no file write on remote failure)
3. Run focused boundary test file first, then broader suite if needed.
4. Record rationale and rollback in PR evidence.

## Focused Test Command
```bash
bundle exec ruby -S rspec --format progress spec/unit/api_client/registration_spec.rb
```

## Risk Notes
- Contract tightening may expose integrations that relied on malformed server responses.
- Retry behavior assertions are config-sensitive; changes to defaults should update tests and docs together.
- Filesystem-side effect assertions are critical to prevent partial bootstrap state.

## Rollback Guidance
- Revert commit:
  - git revert <commit_sha>
- Or restore only scoped files:
  - git checkout -- lib/chef/api_client/registration.rb
  - git checkout -- spec/unit/api_client/registration_spec.rb
  - git checkout -- ai-track-docs/api-client-registration-boundary-validation.md
