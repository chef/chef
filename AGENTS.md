# CI preflight

## Debian 12 GitHub Actions migration (2026-11-05)

- [x] GitHub CLI has repository write access. No new workflow permissions or token
  scopes are required.
- [x] The published `dokken/debian-12` image is already configured and the
  existing chef-18 Debian 12 Kitchen job passes.
- [x] `CHEF_LICENSE_KEY` exists in repository secrets and is used by existing
  Kitchen jobs. No license settings change.
- [x] No `CHEF_TOKEN`, Buildkite pipeline access, SSH deploy keys, Habitat
  credentials, or signing keys are added or changed. Do not replace the shared
  chef-ci deploy key.

## Chef Foundation installer repair (2026-11-05)

- [x] Existing Buildkite verify credentials and GitHub repository write access
  have been verified. No new tokens, scopes, deploy keys, or signing keys.
- [x] Use the root Omnitruck installer and the `stable` channel for the existing
  pinned Foundation version in Linux/Windows verify and Linux Omnibus builds.
- [x] Buildkite token has `read_pipelines`, `read_builds`, and `write_builds`
  scopes and can access the chef-18 verify pipeline for reruns.
- [ ] Package access still requires runtime validation: previous stable-channel
  package probes returned HTTP 402. No license credentials are changed here.
