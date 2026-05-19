# System Overview

Chef Infra is a Ruby-based configuration management system that converges machines to a desired state.
This repository contains the Chef Infra Client core, related component gems, packaging assets, and test suites.

## Main Components

- `lib/chef/`: Chef Infra Client runtime and core DSL behavior.
- `chef-config/`: Configuration model and helpers used by the client and supporting tools.
- `chef-utils/`: Shared utility library used across Chef components.
- `chef-bin/`: Entrypoints and command-line wrappers (for example `chef-client`, `chef-solo`).
- `distro/` and `habitat/`: Distribution, packaging, and release artifacts.
- `spec/`, `kitchen-tests/`, and `test/`: Unit, functional, integration, and target-mode test coverage.

## High-Level Runtime Flow

1. A CLI entrypoint in `chef-bin/bin/` starts the Chef process.
2. Configuration is loaded and normalized via `chef-config` and core config code.
3. Cookbook policy and node context are built.
4. Resources are compiled and converged by providers.
5. Reporting, event handlers, and exit status are emitted.

## Design Notes

- Ruby is the primary implementation language.
- Backward compatibility and cross-platform behavior are core constraints.
- Packaging and test execution are split by concern to support local and CI workflows.
