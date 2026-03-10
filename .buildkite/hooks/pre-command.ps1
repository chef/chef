# Pre-command hook for Windows agents.
# Goals:
#  - Match bash pre-command behavior for secrets/SSM
#  - Fix "Unable to locate credentials" on Windows by pulling AWS creds from IMDS when applicable
#  - Never print secrets
#  - Never fail the hook due to git *warnings on stderr* (PowerShell can treat these as terminating errors)

$ErrorActionPreference = "Stop"

# Only execute in the verify pipeline
if ($env:BUILDKITE_PIPELINE_NAME -notmatch '(verify|validate/(release|adhoc|canary))$') { exit 0 }

function Write-Info([string]$Msg) { Write-Output $Msg }

function Test-HasAwsCreds {
  return (
    -not [string]::IsNullOrEmpty($env:AWS_ACCESS_KEY_ID) -and
    -not [string]::IsNullOrEmpty($env:AWS_SECRET_ACCESS_KEY)
  )
}

function Set-AwsRegionDefaults {
  # Match bash region logic (chef => us-west-2, others => us-west-1, skip chef-oss)
  if ([string]::IsNullOrEmpty($env:AWS_REGION)) {
    if ($env:BUILDKITE_ORGANIZATION_SLUG -eq "chef") { $env:AWS_REGION = "us-west-2" }
    else { $env:AWS_REGION = "us-west-1" }
  }

  # Many tools honor AWS_DEFAULT_REGION instead of AWS_REGION
  if ([string]::IsNullOrEmpty($env:AWS_DEFAULT_REGION)) { $env:AWS_DEFAULT_REGION = $env:AWS_REGION }
}

function Set-AwsCredsFromEc2MetadataIfNeeded {
  # Only attempt IMDS creds on the Windows 2019 build step in chef/chef-canary orgs (bash parity)
  if (($env:BUILDKITE_STEP_KEY -ne "build-windows-2019") -or ($env:BUILDKITE_ORGANIZATION_SLUG -notmatch 'chef(-canary)?$')) {
    return
  }

  if (Test-HasAwsCreds) { return }

  # NOTE: We do not print $imdsToken or any returned creds.
  try {
    $imdsToken = Invoke-RestMethod -Method Put -Uri "http://169.254.169.254/latest/api/token" -Headers @{
      "X-aws-ec2-metadata-token-ttl-seconds" = "21600"
    } -TimeoutSec 3

    $roleName = Invoke-RestMethod -Method Get -Uri "http://169.254.169.254/latest/meta-data/iam/security-credentials/" -Headers @{
      "X-aws-ec2-metadata-token" = $imdsToken
    } -TimeoutSec 3

    $resp = Invoke-RestMethod -Method Get -Uri ("http://169.254.169.254/latest/meta-data/iam/security-credentials/{0}" -f $roleName) -Headers @{
      "X-aws-ec2-metadata-token" = $imdsToken
    } -TimeoutSec 3

    $env:AWS_ACCESS_KEY_ID     = $resp.AccessKeyId
    $env:AWS_SECRET_ACCESS_KEY = $resp.SecretAccessKey
    $env:AWS_SESSION_TOKEN     = $resp.Token
  }
  catch {
    throw "Unable to obtain AWS credentials from EC2 Instance Metadata (IMDS). $_"
  }
}

function Get-SSMParameterValue {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Region,
    [switch]$WithDecryption
  )

  $args = @("ssm", "get-parameter", "--name", $Name, "--query", "Parameter.Value", "--output", "text", "--region", $Region)
  if ($WithDecryption) { $args += "--with-decryption" }

  # Do NOT print returned value (secret).
  $value = (& aws @args) 2>&1
  $code = $LASTEXITCODE

  if ($code -ne 0) {
    # Print AWS CLI error text (it *shouldn't* include secrets); helpful for debugging IAM/SSM permission issues
    # but avoid echoing any successful responses.
    if ($value) { $value | ForEach-Object { Write-Info $_ } }
    throw "Failed to read SSM parameter '$Name' (region=$Region). AWS credentials are missing/invalid OR IAM policy denies access."
  }

  return ($value | Out-String).Trim()
}

function Invoke-GitSafe {
  param([Parameter(Mandatory = $true)][string[]]$Args)

  # PowerShell can treat stderr output from native tools as errors.
  # We capture *both* streams and only fail on non-zero exit code.
  $out = (& git @Args) 2>&1
  $code = $LASTEXITCODE
  if ($out) { $out | ForEach-Object { Write-Info $_ } }
  if ($code -ne 0) { throw ("git {0} failed with exit code {1}" -f ($Args -join ' '), $code) }
}

function Try-RebaseOntoMain {
  if ($env:BUILDKITE_BRANCH -eq "main") { return }

  Invoke-GitSafe -Args @("config", "user.email", "you@example.com")
  Invoke-GitSafe -Args @("config", "user.name", "Your Name")

  $main = ((& git show-ref -s --abbrev origin/main) | Out-String).Trim()
  $pr_head = ((& git show-ref -s --abbrev HEAD) | Out-String).Trim()
  $github = "https://github.com/chef/chef/commit/"

  $rebaseOut = (& git rebase origin/main) 2>&1
  $rebaseCode = $LASTEXITCODE
  if ($rebaseOut) { $rebaseOut | ForEach-Object { Write-Info $_ } }

  if ($rebaseCode -eq 0) {
    & buildkite-agent annotate --style success --context ("rebase-pr-branch-{0}" -f $main) ("Rebased onto main ([{0}]({1}{0}))." -f $main, $github)
    return
  }

  # Abort rebase (best effort, never fail hook on abort warnings)
  try { (& git rebase --abort) *> $null } catch { }

  & buildkite-agent annotate --style warning --context ("rebase-pr-branch-{0}" -f $main) ("Couldn't rebase onto main ([{0}]({1}{0})), building PR HEAD ([{2}]({1}{2}))." -f $main, $github, $pr_head)
}

# --- Main flow ---

# Helpful no-op parity with bash: docker ps || true
try { docker ps *> $null } catch { }

# Get Chef Foundation + Omnibus toolchain versions (non-secret)
if (Test-Path ".buildkite-platform.json") {
  try {
    $json = Get-Content ".buildkite-platform.json" -Raw | ConvertFrom-Json
    if ($null -ne $json.chef_foundation) {
      $env:CHEF_FOUNDATION_VERSION = [string]$json.chef_foundation
      Write-Info "Chef Foundation Version: $env:CHEF_FOUNDATION_VERSION"
    }
    if ($null -ne $json.omnibus_toolchain) {
      $env:OMNIBUS_TOOLCHAIN_VERSION = [string]$json.omnibus_toolchain
      Write-Info "Omnibus Toolchain Version: $env:OMNIBUS_TOOLCHAIN_VERSION"
    }
  }
  catch {
    Write-Info "WARN: Failed to parse .buildkite-platform.json: $_"
  }
}

Set-AwsRegionDefaults
Set-AwsCredsFromEc2MetadataIfNeeded

# Keep origin/main fresh
Write-Info "Fetching origin/main"
Invoke-GitSafe -Args @("fetch", "origin", "main")
Invoke-GitSafe -Args @("fetch", "--tags", "--force")

Try-RebaseOntoMain

# ---- SSM-derived env vars (secrets; do not print) ----
$isMac = ($env:BUILDKITE_LABEL -match 'macOS|mac_os_x')

# If NOT test step and NOT chef-oss: set artifactory creds + rpm signing key
if (($env:BUILDKITE_STEP_KEY -notmatch '^test.*') -and ($env:BUILDKITE_ORGANIZATION_SLUG -ne "chef-oss")) {

  if (-not $isMac) {
    $lita_password = Get-SSMParameterValue -Name "artifactory-lita-password" -Region $env:AWS_REGION -WithDecryption
    $bytes = [System.Text.Encoding]::UTF8.GetBytes(("lita:{0}" -f $lita_password))
    $env:ARTIFACTORY_API_KEY = [Convert]::ToBase64String($bytes)
  }

  $env:ARTIFACTORY_PASSWORD = Get-SSMParameterValue -Name "buildkite-artifactory-docker-full-access-token" -Region $env:AWS_REGION -WithDecryption

  if ($env:BUILDKITE_LABEL -match 'rhel|rocky|sles|centos|amazon') {
    $env:RPM_SIGNING_KEY = Get-SSMParameterValue -Name "packages-at-chef-io-signing-cert" -Region $env:AWS_REGION -WithDecryption
  }
}

# If build-* step on chef/chef-canary and NOT mac: set omnibus cache creds
if (($env:BUILDKITE_STEP_KEY -match '^build-.*') -and
    ($env:BUILDKITE_ORGANIZATION_SLUG -match 'chef(-canary)?$') -and
    (-not $isMac)) {

  $env:AWS_S3_ACCESS_KEY = Get-SSMParameterValue -Name "omnibus-cache-aws-access-key-id-private" -Region $env:AWS_REGION -WithDecryption
  $env:AWS_S3_SECRET_KEY = Get-SSMParameterValue -Name "omnibus-cache-aws-secret-access-key-id-private" -Region $env:AWS_REGION -WithDecryption
}

# Only for build steps that need omnibus-private access
if (($env:BUILDKITE_STEP_KEY -match '^build-.*') -and ($env:BUILDKITE_ORGANIZATION_SLUG -ne "chef-oss")) {

  # Load clone-only GitHub token from SSM
  if ([string]::IsNullOrEmpty($env:GITHUB_TOKEN)) {
    $env:GITHUB_TOKEN = Get-SSMParameterValue -Name "buildkite-github-clone-only-token" -Region $env:AWS_REGION -WithDecryption
  }

  if ([string]::IsNullOrEmpty($env:GITHUB_TOKEN)) {
    throw "GITHUB_TOKEN could not be loaded from SSM."
  }

  # Prevent git from hanging on prompts
  $env:GIT_TERMINAL_PROMPT = "0"

  # Do NOT persist token in git config here (avoids writing secret to .git/config).
  # Downstream scripts should use in-memory env vars (e.g., Bundler via BUNDLE_GITHUB__COM).
  if ([string]::IsNullOrEmpty($env:OMNIBUS_SUBMODULE_CONFIG_PRIVATE)) {
    $env:OMNIBUS_SUBMODULE_CONFIG_PRIVATE = $env:GITHUB_TOKEN
  }
}