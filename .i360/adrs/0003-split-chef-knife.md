---
status: proposed
date: 2025-12-15
decision-makers: Progress Chef Architecture, project owner
consulted: Product Management, Legal & Licensing, Release Engineering, project advisor
informed: Engineering, Support, Marketing, Partner Enablement, Community, contributors, reviewers, approver
---

# Splitting Chef Knife into a Standalone Repository and Package

## Context and Problem Statement

Chef Knife has historically been developed and distributed as part of the core `chef/chef` repository and bundled directly with Chef Infra Client. While this model made sense in earlier iterations of Chef, it has become increasingly misaligned with modern operational, security, and packaging expectations.

Knife is a **management and orchestration tool**, not a runtime requirement for Chef Infra Client execution on managed nodes. Bundling it directly into the core client (or other packages) introduces several problems:

* **Increased package size and dependency bloat**, driven by Knife plugins and optional backends (e.g., WinRM, cloud SDKs).
* **Security and compliance concerns**, as a best practice customers should limit management tooling on production nodes, and not be required to install a bundle of software to access knife.
* **Slower release velocity**, because Knife changes are coupled to Chef Infra Client release cycles.
* **Inflexible packaging**, preventing Knife from being installed only where it is required.

Chef has already taken steps in this direction historically. In Chef Infra Client 17, Knife was split into its own Ruby gem to reduce size and address security concerns. However, the codebase and release lifecycle remain tightly coupled to the core Chef repository.

This ADR formalizes the next logical step: **fully separating Knife into its own repository and treating it as an optional, explicitly packaged tool**.

## Intent and Scope

The intent of this decision is to:

* Decouple Knife development and releases from Chef Infra Client.
* Reduce security and compliance risk by default.
* Improve modularity, packaging flexibility, and future evolution.
* Align with Chef’s broader move toward composable tooling (Habitat, Courier, Agentless, Outpost).

This ADR does **not** change Knife functionality, CLI semantics, or plugin APIs. It strictly addresses **source ownership, packaging, and distribution boundaries**.

## Decision Drivers

* Desire to minimize Chef Infra Client dependencies (actual or perceived).
* Proven precedent from Chef Infra Client 17 separating Knife into its own gem.
* Need for independent release cadence and faster iteration.
* Alignment with Habitat-based packaging and Chef 360 modular architecture.
* Clear separation between **node runtime** and **operator tooling**.

## Considered Options

### Option A – Keep Knife in the Core Chef Repository

Continue maintaining Knife code inside `chef/chef`, bundling it into Chef Workstation.

### Option B – Split Knife into a Separate Repository and Package It Explicitly (Selected)

Move Knife into its own repository with its own build, test, and release lifecycle. Include Knife only in products or packages that explicitly require it.

### Option C – Deprecate Knife Entirely

Replace Knife with APIs, UI-driven workflows, or other tooling.

**Rejected** as premature and disruptive.

## Decision Outcome

Progress Chef will:

1. **Create a new standalone repository** for Chef Knife.
2. **Move all Knife-related source code** (core CLI and built-in commands) into this repository.
3. **Establish independent versioning and release pipelines** for Knife.
4. **Remove Knife as a hard dependency** from all tools and bundles.
5. **Package Knife explicitly at build time** for:
   * Chef Workstation
   * Chef Server administration bundles
   * Specific Habitat packages where required
6. **Provide Knife as a standalone Habitat package** (e.g., `chef/knife`) for optional installation.

Chef Infra Client installations will **not** include Knife by default.

## Consequences

### Positive

* Independent Knife release cadence.
* Cleaner separation of concerns between runtime and tooling.
* Improved compliance posture for regulated customers.
* Alignment with modular, composable product strategy.

### Neutral

* Additional repository and release management overhead.
* Requires documentation updates for installation guidance.
* Some users must explicitly install Knife where previously implicit.

### Negative

* Initial migration effort to extract and stabilize the new repository.
* Temporary confusion during transition period.
* Requires coordination across packaging systems (Omnibus, Habitat, Workstation).

## Architecture / Implementation Overview

* Knife will live in a dedicated Git repository (e.g., `chef/knife`).
* The repository will:
  * Publish a Ruby gem for development and plugin compatibility.
  * Build a Habitat package for operational use.
* Chef Infra Client will:
  * Remove all direct Knife dependencies.
  * Treat Knife as an external tool.
* Chef Workstation will:
  * Continue to bundle Knife explicitly (but Workstation will shift to a meta package instead of a bundle)
* Habitat packaging will allow:
  * `hab pkg install chef/knife`
  * Fine-grained control over where Knife exists.

## Security and Supply Chain Considerations

* Independent distribution and packaging improves provenance clarity.
* Habitat-based delivery enables stronger dependency isolation.
* Plugin dependencies are no longer transitively introduced to all nodes.

## Confirmation

This decision will be validated by:

* Successful Chef Infra Client builds without Knife.
* Knife released independently with no loss of functionality.
* Habitat package availability and installation success.
* Customer validation that Knife is no longer present on managed nodes by default.
* Security review confirming reduced dependency and attack surface.

## Pros and Cons of the Options

To be expanded as required.

## FAQ / Feedback

To be populated from PR and community feedback.

## More Information

* Chef Infra Client 17 Knife separation discussion (GitHub issue #11019)
* Chef Workstation release notes on Knife dependency management
