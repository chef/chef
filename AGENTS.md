# CI preflight

## Main Buildkite Debian 12 verify repair (2026-11-05)

- [x] GitHub CLI has repository write access; Buildkite token has `read_builds`,
  `read_build_logs`, `read_pipelines`, and `write_builds`.
- [x] Official Docker Hub `debian:12` is published for amd64 and arm64. Existing
  `default-privileged` and `default-privileged-aarch64` queues ran this build.
- [x] Existing `HAB_AUTH_TOKEN` access is evidenced by successful non-Debian
  verify jobs in build 24353. No new license or registry credentials are needed.
- [x] No `CHEF_TOKEN`, deploy keys (including chef-ci), signing keys, or token
  scopes are added or changed.

## Debian 12 GitHub Actions migration (2026-11-05)

- [x] GitHub CLI has repository write access. Workflows retain `contents: read`;
  no new GitHub token scopes are required.
- [x] Official `debian:12` supports amd64 and arm64. Use it for unit/functional
  jobs, which install Ruby themselves, rather than an unpublished toolchain image.
- [x] Existing Debian 12 Kitchen jobs pass on both architectures, exercising the
  existing Habitat authentication and package access.
- [x] `CHEF_LICENSE_KEY` exists in repository secrets. No license settings change.
- [ ] Organization secrets cannot be enumerated with the current token
  (`admin:org` unavailable). `HAB_AUTH_TOKEN` is configured by the existing
  workflow and its access is evidenced by successful Debian 12 Kitchen runs.
- [x] No `CHEF_TOKEN`, Buildkite pipeline access, SSH deploy keys, or signing keys
  are added or changed. Do not replace the shared chef-ci deploy key.
