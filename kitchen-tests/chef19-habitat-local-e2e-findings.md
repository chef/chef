# Chef 19 / Habitat Local End-to-End Test Findings

Goal: validate that the `end_to_end` cookbook's Windows suite converges successfully
against Chef Infra Client 19 installed via Habitat, running locally via the `exec`
driver/transport (`kitchen.exec.windows.yml`) before attempting remote (Azure) runs.

## Environment
- Local Windows machine, `exec` driver/transport (no VM)
- Chef Infra Client 19.3.15, installed via `hab pkg install chef/chef-infra-client`
- `chef-test-kitchen-enterprise` 2.0.15 (Chef Workstation 26.1.0)

## Findings

### 1. `chef_license_key` validation intermittently fails
- **Symptom**: `License key validation failed: license is not entitled to the given
  entitlemetGuid` or `invalid licenseId`, even with a freshly-generated free-trial key
  from https://www.chef.io/license-generation-free-trial.
- **Root cause**: two separate local overrides were pointing license validation at an
  internal acceptance/QA endpoint instead of production:
  - `$env:CHEF_LICENSE_SERVER` was hardcoded in the PowerShell profile to
    `https://licensing-acceptance.chef.co/License`.
  - `~/.chef/licenses.yaml` persists whatever `license_server_url` was last resolved,
    independent of env vars, so clearing the env var alone doesn't help once this file
    has cached the wrong value.
- **Fix for real customer-flow validation**: unset `CHEF_LICENSE_SERVER`, clear/rename
  `~/.chef/licenses.yaml`, get a fresh key from the public self-service portal.
- **Fix used to unblock local testing**: set `download_url` (any truthy value) on the
  `chef_infra` provisioner. `ChefBase#bypass_chef_licensing?` treats a configured
  `download_url` as "you already have your own install," skipping the license-key HTTP
  check entirely. Safe here because `install_strategy: skip` means `download_url` is
  never actually used to download anything.

### 2. `hab pkg install --binlink` can report a non-zero exit code on a successful install
- **Symptom**: our `pre_converge` Habitat-bootstrap script treated `hab pkg install`'s
  exit code as authoritative and failed the whole run, even though the log showed the
  package installed and every binary binlinked successfully.
- **Root cause**: "Binlink destination '...' is not on the PATH" warnings during
  `--binlink` appear to cause a non-zero process exit in some cases, independent of
  whether the actual package install succeeded.
- **Fix**: verify success by checking for the actual expected artifact
  (`C:\hab\bin\chef-client.bat` exists) instead of trusting the exit code. (Only
  relevant to the Azure/`pre_converge` bootstrap flow, not the local exec flow, which
  already had chef-client available via Habitat.)

### 3. `habitat_sup` resource silently skips starting the Windows Service under a
   Habitat-packaged chef-client
- **Symptom**: `_habitat_win_service.rb`'s `wait-for-svc-default-startup` block failed
  with `Habitat service is not running yet` (checks `(Get-Service habitat).Status`).
- **Root cause**: `Chef::Resource::HabitatSupWindows#action :run` has:
  ```ruby
  service "Habitat" do
    action %i{enable start}
    not_if { node["chef_packages"]["chef"]["chef_root"].include?("/pkgs/chef/chef-infra-client") }
  end
  ```
  When chef-client itself runs from a Habitat package (our exact setup), this resource
  intentionally never installs/starts the real "Habitat" Windows Service, assuming one
  is already managed externally.
- **Local fix**: the Windows Service was already registered (`core/windows-service`)
  but stopped; starting it manually (`Start-Service Habitat`) unblocked this check.
  Just having `hab sup run` running in a foreground terminal does **not** satisfy this
  check -- it specifically polls the registered Windows Service, not Supervisor
  reachability in general.
- **Open question**: is this `not_if` guard intentional upstream behavior customers are
  expected to work around themselves, or a gap in the Habitat-based chef-client
  packaging story? Worth raising.

### 4. `chef/splunkforwarder` Habitat package's `run` hook has a PATH bug on Windows
- **Symptom**: once the Habitat Windows Service was running, `hab svc status` showed
  `chef/splunkforwarder` loaded but `state: down` (no PID). The Supervisor's own log
  showed repeated `splunk: The term 'splunk' is not recognized...` errors from the
  service's init/run hooks, in a permanent crash-restart loop.
- **Root cause**: Splunk Universal Forwarder is fully bundled inside the
  `chef/splunkforwarder` Habitat package itself
  (`C:\hab\pkgs\chef\splunkforwarder\<version>\bin\bin\splunk.exe`) -- it is **not**
  expected to be pre-installed separately on the test platform. The package's own
  `PATH` file correctly declares `bin/bin` as a bin directory. However,
  [hooks/run](C:/hab/pkgs/chef/splunkforwarder/7.0.3/20250714155325/hooks/run) invokes
  the bare `splunk` command, relying on PATH resolution -- and when the Supervisor
  runs as the Windows Service, that process's environment does not pick up the
  package's declared PATH entry, so `splunk` is never found.
- **Status**: appears to be a genuine packaging/hook bug in this version of
  `chef/splunkforwarder` (or in how the Habitat Windows Service composes PATH for
  supervised services), not a local environment gap. Same general class of issue as
  the earlier `net.exe`/`auditpol.exe` PATH gaps found under Habitat-launched
  processes in the ARM cookbook work.
- **Decision**: rather than patch the vendored package's hook script directly (fragile,
  wiped out on any reinstall), skip `_habitat_win_service.rb` for this local
  validation pass (see `cookbooks/end_to_end/recipes/windows.rb`) and continue
  exercising the rest of the `end_to_end::default` run list. Revisit once this is
  reported/tracked upstream.

### 5. No Habitat packages are published for the `aarch64-windows` target at all
- **Context**: this is the actual reason `end_to_end_arm` excludes all Habitat
  coverage -- confirmed via the Habitat Builder API (`bldr.habitat.sh`), not assumed.
- **Finding**: `aarch64-windows` is a formally supported package target in Habitat's
  own core Rust source
  (`components/core/src/package/target.rs` defines `AARCH64_Windows`), so this is not
  an architectural limitation of Habitat itself. However, none of the packages that
  Windows-side Habitat testing depends on have ever been built/published for it:

  | Package | Needed for | Platforms actually published |
  |---|---|---|
  | `core/hab-sup` | The Supervisor itself | `x86_64-windows`, `x86_64-linux`, `aarch64-linux` -- no `aarch64-windows` |
  | `core/hab-launcher` | Supervisor launcher | `x86_64-windows`, `x86_64-linux`, `x86_64-linux-kernel2` -- no `aarch64-windows` |
  | `core/windows-service` | Registers the "Habitat" Windows Service | `x86_64-windows` only -- no `aarch64-windows` |
  | `chef/splunkforwarder` | Exercised by `_habitat_win_*.rb` recipes | `x86_64-windows`, `x86_64-linux` -- no `aarch64-windows` |

- **Status**: nobody has built/published `aarch64-windows` artifacts for these
  packages yet -- a packaging/publishing gap, not something fixable from our cookbooks
  or kitchen config. Blocks any Habitat-based testing on Windows ARM64 until these are
  published, regardless of what else is fixed.

## `end_to_end` vs `end_to_end_arm` cookbook comparison

`end_to_end_arm` is a deliberately narrower subset of `end_to_end`, built to sidestep
things known to be missing/broken on Windows ARM64 (no ARM64 Habitat builds, no
pre-staged fixture files). Compared directly:

| | `end_to_end` | `end_to_end_arm` |
|---|---|---|
| **Scope** | Cross-platform: `default.rb` dispatches to `linux.rb`, `macos.rb`, or `windows.rb` | Windows-only: `default.rb` is just `include_recipe "::windows" if windows?` |
| **Recipe count** | ~40 recipes | 6 recipes |
| **Habitat coverage** | `_habitat_config`, `_habitat_install_no_user`, `_habitat_package`, `_habitat_service`, `_habitat_sup`, `_habitat_user_toml` (Linux/macOS) plus `_habitat_win_*` (config/package/service/sup/user_toml) for Windows | None at all -- by design, since no `aarch64-windows` Habitat builds exist (see finding #5) |
| **Windows-specific recipes** | `_windows_defender`, `_windows_printer`, `_windows_user_privilege`, `_powershell_package`, `_chef_client_hab_ca_cert`, `_chef_client_trusted_certificate`, `_chef_client_config` | `_misc`, `_security_policy` (consolidates defender/printer/user_privilege/firewall/audit-policy coverage), `_certificates`, `_archive`, `_openssl`, `_chef_client` (consolidates config + trusted_certificate coverage) |
| **File/fixture assumptions** | Assumes some files are pre-staged under `files/`, and depends on external community cookbooks (`ntp`, `git`) | Deliberately self-contained -- every test that needs a file creates it first; no external cookbook dependencies |

### Additional divergences not obvious from the recipe list alone
- **`_windows_user_privilege.rb` in `end_to_end` is never actually included/run.**
  Confirmed by searching every recipe file in the cookbook for an
  `include_recipe "::_windows_user_privilege"` call -- there isn't one, in
  `windows.rb` or anywhere else. It's dead code. `end_to_end_arm`'s consolidated
  `_security_policy.rb` *does* exercise `windows_user_privilege`, so on this one
  resource `end_to_end_arm` currently has more real coverage than `end_to_end`.
- **`_powershell_package.rb` in `end_to_end` is also never included/run anywhere**
  (same search, same result). So `powershell_package` currently has zero real test
  coverage in *either* cookbook -- not something `end_to_end_arm` is missing relative
  to `end_to_end`, but a shared gap worth fixing in both. `powershell_package`
  installs PowerShell Gallery modules, which are architecture-agnostic script content,
  so there's no known reason this couldn't be added to `end_to_end_arm` directly.
- **`_chef_client_config.rb`'s `additional_config` attribute** (a heredoc that
  conditionally `require`s `aws-sdk`) is present in `end_to_end` but missing from
  `end_to_end_arm`'s consolidated `_chef_client.rb` -- a small, easy gap to close.
- **`_chef_client_hab_ca_cert.rb`** is only conditionally included in `end_to_end`
  (`if ::File.exist?("C:/ProgramData/Habitat/hab.exe")`) and tests
  `chef_client_hab_ca_cert`, which installs Habitat's own CA cert -- inherently
  Habitat-dependent, so consistent with `end_to_end_arm` having no equivalent.
- **`ntp` and `git`** are external community cookbook dependencies pulled into
  `end_to_end`'s `windows.rb`; `end_to_end_arm` avoids all external cookbook
  dependencies by design.

## Still to validate
- Full run of `end_to_end::default` on chef-19/Habitat locally, past the skipped
  `_habitat_win_service` recipe.
- Whether `_habitat_win_config.rb` and `_habitat_win_sup.rb` (both also touch
  `habitat_sup`) hit the same Windows-Service/PATH issues once exercised fully.
- Re-running the same suite against the Azure/remote path once local validation is
  clean, to confirm parity.
