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

  # IMPORTANT: do NOT echo the returned value; treat it as a secret.
  $value = (& aws @args) 2>$null
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to read SSM parameter '$Name' (region=$Region). AWS credentials are missing/invalid for this job."
  }

  return ($value | Out-String).Trim()
}

function Set-AwsCredsFromEc2MetadataIfNeeded {
  # Bash parity:
  # if [[ "$BUILDKITE_STEP_KEY" == "build-windows-2019" ]] && [[ "$BUILDKITE_ORGANIZATION_SLUG" =~ chef(-canary)?$ ]]
  # then pull credentials from IMDSv2 and export AWS_* vars
  if (($env:BUILDKITE_STEP_KEY -eq "build-windows-2019") -and ($env:BUILDKITE_ORGANIZATION_SLUG -match 'chef(-canary)?$')) {

    $haveCreds =
      -not [string]::IsNullOrEmpty($env:AWS_ACCESS_KEY_ID) -and
      -not [string]::IsNullOrEmpty($env:AWS_SECRET_ACCESS_KEY)

    if ($haveCreds) { return }

    try {
      # IMDSv2 token (this is NOT an AWS credential; it's a one-time metadata session token)
      $imdsToken = Invoke-RestMethod -Method Put -Uri "http://169.254.169.254/latest/api/token" -Headers @{
        "X-aws-ec2-metadata-token-ttl-seconds" = "21600"
      } -TimeoutSec 3

      $roleName = Invoke-RestMethod -Method Get -Uri "http://169.254.169.254/latest/meta-data/iam/security-credentials/" -Headers @{
        "X-aws-ec2-metadata-token" = $imdsToken
      } -TimeoutSec 3

      $resp = Invoke-RestMethod -Method Get -Uri ("http://169.254.169.254/latest/meta-data/iam/security-credentials/{0}" -f $roleName) -Headers @{
        "X-aws-ec2-metadata-token" = $imdsToken
      } -TimeoutSec 3

      # Set env vars for aws cli to use.
      # We do NOT print these values; they remain in-memory environment variables for this job.
      $env:AWS_ACCESS_KEY_ID     = $resp.AccessKeyId
      $env:AWS_SECRET_ACCESS_KEY = $resp.SecretAccessKey
      $env:AWS_SESSION_TOKEN     = $resp.Token
    }
    catch {
      throw "Unable to obtain AWS credentials from EC2 Instance Metadata (IMDS). $_"
    }
  }
}

# Helpful no-op parity with bash: docker ps || true
try { docker ps *> $null } catch { }

# Get Chef Foundation + Omnibus toolchain versions (non-secret)
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

# Force regions (non-secret)
if ([string]::IsNullOrEmpty($env:AWS_REGION)) {
  if ($env:BUILDKITE_ORGANIZATION_SLUG -eq "chef") { $env:AWS_REGION = "us-west-2" }
  else { $env:AWS_REGION = "us-west-1" }
}
if ([string]::IsNullOrEmpty($env:AWS_DEFAULT_REGION)) { $env:AWS_DEFAULT_REGION = $env:AWS_REGION }

# Ensure AWS creds exist for the Windows 2019 build step (fixes "Unable to locate credentials")
Set-AwsCredsFromEc2MetadataIfNeeded

# GitHub auth setup (uses token but does not print it; git config will store it in .git/config in the workspace)
# NOTE: If you consider persisting token in .git/config too risky, remove this and rely on bundler env vars instead.
if (-not [string]::IsNullOrEmpty($env:GITHUB_TOKEN)) {
  $env:GIT_TERMINAL_PROMPT = "0"
  git config --local url."https://x-access-token:$($env:GITHUB_TOKEN)@github.com/".insteadOf "https://github.com/"
}
else {
  Write-Output "GITHUB_TOKEN not set. Skipping GitHub auth setup."
}

# Keep origin/main fresh (non-secret)
Write-Output "Fetching origin/main"
git fetch origin main
git fetch --tags --force

# Rebase onto current main (non-secret)
if ($env:BUILDKITE_BRANCH -ne "main") {
  git config user.email "you@example.com"
  git config user.name "Your Name"

  $main = (git show-ref -s --abbrev origin/main).Trim()
  $pr_head = (git show-ref -s --abbrev HEAD).Trim()
  $github = "https://github.com/chef/chef/commit/"

  git rebase origin/main *> $null
  if ($LASTEXITCODE -eq 0) {
    buildkite-agent annotate --style success --context "rebase-pr-branch-$main" "Rebased onto main ([$main]($github$main))."
  }
  else {
    git rebase --abort *> $null
    buildkite-agent annotate --style warning --context "rebase-pr-branch-$main" "Couldn't rebase onto main ([$main]($github$main)), building PR HEAD ([$pr_head]($github$pr_head))."
  }
}

# ---- SSM-derived env vars (these values are secrets; do not print them) ----
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

  if ([string]::IsNullOrEmpty($env:GITHUB_TOKEN)) {
    $env:GITHUB_TOKEN = Get-SSMParameterValue -Name "buildkite-github-clone-only-token" -Region $env:AWS_REGION -WithDecryption
  }

  if ([string]::IsNullOrEmpty($env:GITHUB_TOKEN)) {
    throw "GITHUB_TOKEN could not be loaded from SSM."
  }

  # Prevent git from hanging on prompts
  $env:GIT_TERMINAL_PROMPT = "0"

  # Match bash exporting OMNIBUS_SUBMODULE_CONFIG_PRIVATE
  if ([string]::IsNullOrEmpty($env:OMNIBUS_SUBMODULE_CONFIG_PRIVATE)) {
    $env:OMNIBUS_SUBMODULE_CONFIG_PRIVATE = $env:GITHUB_TOKEN
  }
}
