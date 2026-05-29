# Target IO Static Analysis Suppressions (2026-05-29)

## Scope

- `lib/chef/target_io/train/dir.rb`
- `lib/chef/target_io/train/file.rb`
- `lib/chef/target_io/train/fileutils.rb`
- `lib/chef/target_io/train/http.rb`

## Suppression

- Cop: `Chef/Deprecations/UsesRunCommandHelper`

## Justification

The cop flags methods named `run_command` regardless of receiver context. In these files, `run_command` is `TargetIO::Support#run_command`, which delegates to Train transport (`transport_connection.run_command`) and is not the removed Chef shell helper API targeted by this cop.

## Safety

The suppression is file-scoped and narrowly limited to the train transport adapter implementation files where this intentional pattern exists.

## Follow-up

If Cookstyle introduces a transport-aware variant of this cop, remove these suppressions and re-run `scripts/target_io_static_analysis.sh`.
