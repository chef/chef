# CI preflight

## Debian 12 Buildkite/Omnibus migration (2026-11-05)

- [x] GitHub CLI has repository write access and the existing Buildkite read token
  can read chef-oss verify builds. No `CHEF_TOKEN` or new token scopes are needed.
- [x] Existing verify jobs pass. Buildkite agent credentials continue to supply
  pipeline-upload, metadata, and artifact access.
- [x] Existing Omnibus build hooks source Artifactory credentials, the GitHub
  clone-only token, package-signing key and S3 cache credentials from AWS SSM.
  Their secret sources and IAM configuration are unchanged.
- [ ] Worker-side SSM, Artifactory, signing and S3 access must be verified by a
  Debian 12 build; successful public verify jobs do not prove private build access.
- [ ] BLOCKER: publish `chefes/omnibus-toolchain-debian-12` with the configured
  x86_64 toolchain tag (currently `3.0.39`) before running container builds/tests.
- [ ] BLOCKER: provision Debian 12 x86_64 and aarch64 Omnibus workers for the
  Expeditor builder/tester maps; verify toolchain, Chef Foundation installation,
  package signing/publishing and the existing worker credentials.
- [x] No deploy keys are created or replaced (especially the shared chef-ci key).
  No license settings or existing signing credentials are changed.
