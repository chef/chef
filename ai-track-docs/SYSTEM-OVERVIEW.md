# System Overview

Chef Infra is a Ruby-based configuration management system that converges machines to a desired state.
This repository contains the Chef Infra Client core, related component gems, packaging assets, and test suites.

## Languages and Formats

- Ruby: primary implementation language for runtime, libraries, and rake tasks.
- YAML: CI/CD workflows and task orchestration in `.github/workflows/`.
- ERB/templates and scripts: documentation/build templating and platform automation support.

## Concrete Entry Points

### Runtime / CLI

- `chef-bin/bin/chef-client` -> boots `Chef::Application::Client`.
- `chef-bin/bin/chef-solo` -> boots `Chef::Application::Solo`.
- `chef-bin/bin/chef-apply` -> boots `Chef::Application::Apply`.
- `lib/chef.rb` -> core library entry that requires config/providers/resources and target IO wiring.

### Build / Task Entry

- `Rakefile` -> top-level task entry that loads task namespaces from `tasks/`.

## Main Components

- `lib/chef/`: Chef Infra Client runtime and DSL behavior.
- `chef-config/lib/`: Configuration model and helper code.
- `chef-utils/lib/`: Shared utility code used across Chef components.
- `chef-bin/bin/`: CLI wrappers and executable entry scripts.
- `distro/` and `habitat/`: Packaging and distribution assets.
- `spec/`, `kitchen-tests/`, and `test/`: test suites and validation scaffolding.

## Test Approach

- RSpec task decomposition in `tasks/rspec.rb`:
  - `rake spec:unit`
  - `rake spec:functional`
  - `rake spec:integration`
  - `rake spec:stress`
- Target-mode checks in `tasks/target_mode.rb` (unit, integration, and static-analysis tasks).
- Shared RSpec config and environment filters in `spec/spec_helper.rb`.
- CI matrix coverage:
  - Unit specs: `.github/workflows/unit_specs.yml`
  - Functional specs: `.github/workflows/func_spec.yml`
  - Kitchen/end-to-end validation: `.github/workflows/kitchen.yml` and `kitchen-tests/`

## High-Level Runtime Flow

1. A CLI entrypoint in `chef-bin/bin/` starts the Chef process.
2. Configuration is loaded and normalized via `chef-config` and core config code.
3. Cookbook policy and node context are built.
4. Resources are compiled and converged by providers.
5. Reporting, event handlers, and exit status are emitted.

## Low-Risk Modules to Modify

1. `tasks/spellcheck.rb`
	- Low risk: developer tooling only; does not alter converge/runtime behavior.
2. `tasks/docs.rb`
	- Low risk (if scoped): affects generated docs output, not Chef client execution.
3. `ai-track-docs/`
	- Very low runtime risk: documentation-only folder outside runtime paths.

## Recommended Low-Risk Module

Recommended module: `tasks/spellcheck.rb`.

Why this is low risk:

- Narrow blast radius: task is invoked manually/CI for linting and not on chef-client runtime path.
- Fast validation: behavior can be checked quickly with `bundle exec rake spellcheck`.
- Easy rollback: changes are isolated to a single task file.

## Assumptions and How to Verify

Assumptions:

1. `chef-bin/bin/*` scripts are the operational CLI entrypoints used by contributors and CI.
2. `Rakefile` remains the canonical local build/test task entrypoint.
3. Editing `tasks/spellcheck.rb` does not affect runtime convergence behavior.

Verification steps (macOS, bash):

```bash
# Confirm referenced entrypoint files exist
ls chef-bin/bin/chef-client chef-bin/bin/chef-solo chef-bin/bin/chef-apply lib/chef.rb Rakefile

# Confirm task wiring and availability
bundle exec rake -T | rg "spec|spellcheck|target_mode"

# Validate low-risk module behavior only (no runtime path changes)
bundle exec rake spellcheck

# Optional: sanity-check key tests after any task change
bundle exec rake spec:unit
```

If any assumption fails, treat this document as a starting map and update file references based on current task output from `bundle exec rake -T` and CI workflow definitions in `.github/workflows/`.
