$ErrorActionPreference = "Stop"

# Only execute in the verify pipeline
if ($env:BUILDKITE_PIPELINE_NAME -notmatch '(verify|validate/(release|adhoc|canary))$') { exit 0 }

function Get-SSMParameterValue {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Region,
    [switch]$WithDecryption
  )

  $args = @("ssm", "get-parameter", "--name", $Name, "--query", "Parameter.Value", "--output", "text", "--region", $Region)
  if ($WithDecryption) { $args += "--with-decryption" }

  # do NOT echo the returned value (secret)
  $value = (& aws @args) 2>&1
  $code = $LASTEXITCODE

  if ($code -ne 0) {
    if ($value) { $value | ForEach-Object { Write-Output $_ } }
    throw "Failed to read SSM parameter '$Name' (region=$Region). AWS credentials are missing/invalid OR IAM policy denies access."
  }

  return ($value | Out-String).Trim()
}

function Set-AwsCredsFromEc2MetadataIfNeeded {
  # Match bash behavior on Windows 2019 chef/chef-canary builds
  if (($env:BUILDKITE_STEP_KEY -eq "build-windows-2019") -and ($env:BUILDKITE_ORGANIZATION_SLUG -match 'chef(-canary)?$')) {

    $haveCreds =
      -not [string]::IsNullOrEmpty($env:AWS_ACCESS_KEY_ID) -and
      -not [string]::IsNullOrEmpty($env:AWS_SECRET_ACCESS_KEY)

    if ($haveCreds) { return }

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
}

# docker ps || true
try { docker ps *> $null } catch { }

# Versions from .buildkite-platform.json (non-secret)
if (Test-Path ".buildkite-platform.json") {
  try {
    $json = Get-Content ".buildkite-platform.json" -Raw | ConvertFrom-Json
    if ($null -ne $json.chef_foundation) {
      $env:CHEF_FOUNDATION_VERSION = [string]$json.chef_foundation
      Write-Output "Chef Foundation Version: $env:CHEF_FOUNDATION_VERSION"
    }
    if ($null -ne $json.omnibus_toolchain) {
      $env:OMNIBUS_TOOLCHAIN_VERSION = [string]$json.omnibus_toolchain
      Write-Output "Omnibus Toolchain Version: $env:OMNIBUS_TOOLCHAIN_VERSION"
    }
  }
  catch {
    Write-Output "WARN: Failed to parse .buildkite-platform.json: $_"
  }
}

# Region logic (bash parity)
if ([string]::IsNullOrEmpty($env:AWS_REGION)) {
  if ($env:BUILDKITE_ORGANIZATION_SLUG -eq "chef") { $env:AWS_REGION = "us-west-2" }
  else { $env:AWS_REGION = "us-west-1" }
}
if ([string]::IsNullOrEmpty($env:AWS_DEFAULT_REGION)) { $env:AWS_DEFAULT_REGION = $env:AWS_REGION }

# Fix "Unable to locate credentials" on win2019 by pulling IMDS creds (bash parity)
Set-AwsCredsFromEc2MetadataIfNeeded

# ---- Git fetch + optional rebase ----
# NOTE: git writes some normal messages to stderr; with $ErrorActionPreference=Stop this can kill the hook.
# We temporarily set ErrorActionPreference=Continue around git commands and only fail on non-zero exit code.

Write-Output "Fetching origin/main"

$oldEAP = $ErrorActionPreference
$ErrorActionPreference = "Continue"
git fetch origin main
$fetchCode = $LASTEXITCODE
git fetch --tags --force
$tagsCode = $LASTEXITCODE
$ErrorActionPreference = $oldEAP

if ($fetchCode -ne 0) { throw "git fetch origin main failed (exit code $fetchCode)" }
if ($tagsCode -ne 0) { throw "git fetch --tags --force failed (exit code $tagsCode)" }

# Rebase onto current main to mimic post-merge behavior (bash parity)
if ($env:BUILDKITE_BRANCH -ne "main") {
  $oldEAP = $ErrorActionPreference
  $ErrorActionPreference = "Continue"

  git config user.email "buildkite@chef.io"
  git config user.name "Buildkite"

  $main = (git show-ref -s --abbrev origin/main | Out-String).Trim()
  $pr_head = (git show-ref -s --abbrev HEAD | Out-String).Trim()
  $github = "https://github.com/chef/chef/commit/"

  git rebase origin/main *> $null
  $rebaseCode = $LASTEXITCODE

  $ErrorActionPreference = $oldEAP

  if ($rebaseCode -eq 0) {
    buildkite-agent annotate --style success --context "rebase-pr-branch-$main" "Rebased onto main ([$main]($github$main))."
  }
  else {
    try { git rebase --abort *> $null } catch { }
    buildkite-agent annotate --style warning --context "rebase-pr-branch-$main" "Couldn't rebase onto main ([$main]($github$main)), building PR HEAD ([$pr_head]($github$pr_head))."
  }
}

# ---- SSM-derived env vars (secrets; do not print) ----
$isMac = ($env:BUILDKITE_LABEL -match 'macOS|mac_os_x')

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

if (($env:BUILDKITE_STEP_KEY -match '^build-.*') -and
    ($env:BUILDKITE_ORGANIZATION_SLUG -match 'chef(-canary)?$') -and
    (-not $isMac)) {

  $env:AWS_S3_ACCESS_KEY = Get-SSMParameterValue -Name "omnibus-cache-aws-access-key-id-private" -Region $env:AWS_REGION -WithDecryption
  $env:AWS_S3_SECRET_KEY = Get-SSMParameterValue -Name "omnibus-cache-aws-secret-access-key-id-private" -Region $env:AWS_REGION -WithDecryption
}

if (($env:BUILDKITE_STEP_KEY -match '^build-.*') -and ($env:BUILDKITE_ORGANIZATION_SLUG -ne "chef-oss")) {

  if ([string]::IsNullOrEmpty($env:GITHUB_TOKEN)) {
    $env:GITHUB_TOKEN = Get-SSMParameterValue -Name "buildkite-github-clone-only-token" -Region $env:AWS_REGION -WithDecryption
  }

  if ([string]::IsNullOrEmpty($env:GITHUB_TOKEN)) {
    throw "GITHUB_TOKEN could not be loaded from SSM."
  }

  # Keep for downstream git operations without prompting
  $env:GIT_TERMINAL_PROMPT = "0"

  # Match bash exporting OMNIBUS_SUBMODULE_CONFIG_PRIVATE
  if ([string]::IsNullOrEmpty($env:OMNIBUS_SUBMODULE_CONFIG_PRIVATE)) {
    $env:OMNIBUS_SUBMODULE_CONFIG_PRIVATE = $env:GITHUB_TOKEN
  }
}