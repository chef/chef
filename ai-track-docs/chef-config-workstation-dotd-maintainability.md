# chef-config Workstation DotD Maintainability Guide

## Scope
- Subsystem: chef-config workstation configuration loading
- Workflow: loading base config plus config.d snippets
- Primary code paths:
  - chef-config/lib/chef-config/workstation_config_loader.rb
  - chef-config/lib/chef-config/mixin/dot_d.rb
  - chef-config/spec/unit/workstation_config_loader_spec.rb

## Current Behavior (Verified Against Code)
1. Base config is loaded first when present.
- Code path: chef-config/lib/chef-config/workstation_config_loader.rb (load)
- Behavior: if config_location exists, loader reads and applies that file before config.d.

2. config.d loading is optional and guarded by config_d_dir.
- Code path: chef-config/lib/chef-config/workstation_config_loader.rb (load)
- Behavior: load_dot_d is called only when Config[:config_d_dir] is set.

3. DotD loads only top-level .rb files and ignores non-files.
- Code path: chef-config/lib/chef-config/mixin/dot_d.rb (find_dot_d, dot_d_glob)
- Behavior: glob is path/*.rb and then filtered by File.file?.

4. DotD load order is deterministic.
- Code path: chef-config/lib/chef-config/mixin/dot_d.rb (find_dot_d)
- Behavior: entries are sorted lexically before loading.

5. DotD parsing/evaluation errors bubble up.
- Code path: chef-config/lib/chef-config/mixin/dot_d.rb (load_dot_d -> apply_dot_d_config)
- Behavior: apply_config exceptions are not swallowed.

## Test Coverage for This Workflow
- Integration test file: chef-config/spec/unit/workstation_config_loader_spec.rb
- Relevant examples:
  - lexical order for config.d files
  - ignore non-.rb files
  - ignore directories ending in .rb
  - syntax error propagation from config.d entries

## Extension Guidance
1. If adding new config.d rules, keep deterministic ordering intact.
- Avoid introducing non-deterministic ordering based on filesystem iteration.

2. If changing file matching behavior, update both dot_d mixin docs and loader integration tests.
- Keep path filter explicit so users know what will load.

3. If adding recursive loading, implement it behind an explicit option and add migration notes.
- Current behavior is non-recursive and top-level only.

4. Preserve error visibility for bad snippets.
- Swallowing config.d errors can hide broken deployments.

## Risk Notes
- Runtime config risks: changing order can alter final ChefConfig::Config values when keys overlap.
- Operational risk: broadening file matching can unintentionally execute files not meant as config snippets.
- Debuggability risk: suppressing parse errors can make misconfigurations hard to diagnose.

## Safe Rollback
- Revert this documentation/code-alignment update:
  - git revert <commit_sha>
- Or restore just scoped files:
  - git checkout -- chef-config/lib/chef-config/mixin/dot_d.rb
  - git checkout -- ai-track-docs/chef-config-workstation-dotd-maintainability.md
