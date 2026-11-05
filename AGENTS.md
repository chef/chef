# CI preflight

## Debian 12 Buildkite migration (2026-11-05)

- [x] GitHub CLI has repository write access. No new GitHub token scopes or
  `CHEF_TOKEN` permissions are needed.
- [x] The existing Buildkite read token can read chef-oss verify pipeline builds.
  Buildkite agent credentials continue to provide pipeline upload, metadata, and
  artifact access; no pipeline provisioning is introduced.
- [x] Existing ARM64 verification and Habitat build jobs pass, exercising their
  existing queues and authentication. `HAB_AUTH_TOKEN` is supplied by the
  pre-command hook from AWS SSM; no secret sources or IAM permissions change.
- [x] No SSH deploy keys, signing keys, or license settings are changed. Do not
  replace the shared chef-ci deploy key.
- [ ] BLOCKER: `chefes/omnibus-toolchain-debian-12` is not published. Publish and
  validate its x86_64 toolchain tag (currently `3.0.39`) and `aarch64` tag before
  merging. Both must include the tools used by the existing container scripts.
- [ ] Debian 12 integration/package validation must pass on both architectures
  after those images are published. Static checks do not establish worker IAM
  or image runtime compatibility.
