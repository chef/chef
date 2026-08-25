# Chef 19 / Windows Built-in Resource Support Assessment

**Status: draft, in progress.** This is a living document tracking what level of
support Chef Infra Client 19 has for generic and Windows-specific built-in
resources, based on running the existing [`end_to_end`](cookbooks/end_to_end)
cookbook (not the ARM-specific trimmed-down `end_to_end_arm` cookbook) against
a real chef-19 install. Findings here are not ARM-specific; the ARM64 vagrant
box is just what's currently available for testing.

## Goal

Per direction from leadership: understand what level of support chef-19 has
today for built-in resources (generic + Windows), without focusing on
anything ARM-specific, and document limitations at a high level. The
`end_to_end` cookbook's windows recipes (including the `habitat_win_*`
recipes) are assumed to already cover most generic and Windows resources, so
this is primarily a matter of running it against chef-19 and recording what
breaks.

## Test setup

- Cookbook under test: `cookbooks/end_to_end` (run_list `end_to_end::default`)
- Chef Infra Client version: 19.x, installed via Habitat (`hab pkg install
  chef/chef-infra-client`) since chef-19 is not published via the
  omnitruck/MSI installer path
- Kitchen driver: `vagrant` (VirtualBox), currently on a Windows 11 ARM64 box
  (`stromweld/windows-11`); Azure (`kitchen-azurerm`) testing planned as a
  follow-up for a non-ARM Windows target
- Verifier: InSpec, against `test/integration/end-to-end`

## Summary

_To be filled in once a full run against `end_to_end::default` completes._

| Metric | Value |
| --- | --- |
| Total InSpec controls | TBD |
| Passing | TBD |
| Failing | TBD |

## Known limitations found so far

These were found while building/debugging the trimmed `end_to_end_arm`
cookbook against chef-19, and are general chef-19/Habitat-on-Windows
findings rather than ARM-specific ones -- worth re-confirming against the
full `end_to_end` run:

| Resource / Area | Issue | Notes |
| --- | --- | --- |
| Habitat-launched `chef-client` process (general) | `C:\Windows\System32` is not on `PATH` | Any built-in resource that shells out to a bare system utility name (`net`, `auditpol`, etc.) fails with "not recognized as an internal or external command". Affects multiple resources below. Workaround: prepend `System32` to `ENV['PATH']` early in the run. |
| `windows_security_policy` (`LockoutBadCount`, `LockoutDuration`, `ResetLockoutCount`) | Uses `net accounts` internally | Fails due to the PATH issue above. `NewGuestName`/`EnableGuestAccount` (secedit-based) were unaffected. |
| `windows_audit_policy` | Uses `auditpol` internally | Fails due to the PATH issue above. |
| `timezone` | `load_current_resource` shells out to `tzutil /g` | Fails with `RuntimeError: There was an error running the tzutil command` even before attempting to set anything. Root cause not yet isolated (may also be a PATH issue, not yet confirmed). |
| `hostname` (chef-client 18.11.16, not yet re-tested on 19) | Calls `Socket.gethostbyname`, which emits a Ruby deprecation warning to stderr | Under the WinRM transport wrapper (`$ErrorActionPreference = 'Stop'`), that stderr write is treated as a fatal `NativeCommandError` and silently kills chef-client mid-converge. Needs re-verification on chef-19. |

## Habitat-specific recipes (`habitat_win_*`)

_To be filled in._ These install real Habitat packages (splunkforwarder,
sensu-agent-win, etc.) and haven't been exercised yet in this assessment.

## Open questions / next steps

- [ ] Run `end_to_end::default` fully against chef-19 on the current vagrant box and record pass/fail per InSpec control
- [ ] Confirm whether the `hostname` stderr/NativeCommandError issue reproduces on chef-19
- [ ] Determine root cause of the `tzutil` failure (PATH vs. something chef-19-specific)
- [ ] Re-run once Azure (non-ARM) Windows target is available, to separate "chef-19 general" issues from "ARM64 vagrant box" environment quirks
- [ ] Decide whether the PATH (`System32` missing) issue should be fixed upstream (in chef-client's Habitat packaging) rather than worked around per-recipe
