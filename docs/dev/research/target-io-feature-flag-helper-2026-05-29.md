# Target IO Feature Flag Helper Rollout (2026-05-29)

## Flag

- Name: `CHEF_TARGET_IO_BACKEND_HELPER`
- Scope: `TargetIO` wrappers (`File`, `Dir`, `IO`, `FileUtils`)
- Default: disabled (`false` when unset)
- Enable: set `CHEF_TARGET_IO_BACKEND_HELPER=true`

## Purpose

This flag gates adoption of a centralized backend selection helper in `TargetIO` wrappers. It reduces rollout risk for higher-impact refactors by preserving legacy behavior when disabled.

## Toggle Mechanism

`TargetIO::FeatureFlags.target_io_backend_helper_enabled?` reads `ENV["CHEF_TARGET_IO_BACKEND_HELPER"]` and treats `1`, `true`, `yes`, and `on` as enabled.

## Telemetry

When the flag state is evaluated, an info log is emitted once per state transition:

- `TargetIO feature flag CHEF_TARGET_IO_BACKEND_HELPER=true`
- `TargetIO feature flag CHEF_TARGET_IO_BACKEND_HELPER=false`

When the helper path is enabled, backend selection is also debug logged.

## Rollback Path

Immediate rollback is configuration-only:

1. Unset `CHEF_TARGET_IO_BACKEND_HELPER`, or
2. Set `CHEF_TARGET_IO_BACKEND_HELPER=false`

This returns `TargetIO` wrappers to the legacy inline backend-switch logic without code rollback.

## Validation Evidence

Validation is captured by unit tests in both modes:

- OFF mode: wrapper specs force helper off and assert legacy backend switch is used.
- ON mode: wrapper specs force helper on and assert helper-based backend selection is used.
- Telemetry: feature flag spec asserts expected info log lines for both `true` and `false` states.
