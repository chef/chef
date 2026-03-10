# PowerShell 7.3+ can still throw NativeCommandError when a native tool writes to stderr,
# even if the process exits 0. This wrapper forces git stderr to a file and only fails
# on non-zero exit code. This should stop "git.exe : From https://github.com/chef/chef"
# from killing the hook.

$ErrorActionPreference = "Stop"

# Only execute in the verify pipeline
if ($env:BUILDKITE_PIPELINE_NAME -notmatch '(verify|validate/(release|adhoc|canary))$') { exit 0 }

function Write-Info([string]$Msg) { Write-Output $Msg }

function Invoke-GitSafe {
  param([Parameter(Mandatory = $true)][string[]]$Args)

  $stderrFile = Join-Path $env:TEMP ("git-stderr-{0}.log" -f ([guid]::NewGuid().ToString()))
  try {
    $out = & git @Args 2> $stderrFile
    $code = $LASTEXITCODE

    # Emit captured stdout
    if ($out) { $out | ForEach-Object { Write-Info $_ } }

    # Emit captured stderr as plain output (not as an error record)
    if (Test-Path $stderrFile) {
      $errText = Get-Content $stderrFile -Raw
      if (-not [string]::IsNullOrWhiteSpace($errText)) {
        $errText.TrimEnd("`r","`n").Split("`n") | ForEach-Object { Write-Info $_ }
      }
    }

    if ($code -ne 0) { throw ("git {0} failed with exit code {1}" -f ($Args -join ' '), $code) }
  }
  finally {
    Remove-Item -Force $stderrFile -ErrorAction SilentlyContinue
  }
}

function Test-HasAwsCreds {
  return (
    -not [string]::IsNullOrEmpty($env:AWS_ACCESS_KEY_ID) -and
    -not [string]::IsNullOrEmpty($env:AWS_SECRET_ACCESS_KEY)
  )
}

function Set-AwsRegionDefaults {
  if ([string]::IsNullOrEmpty($env:AWS_REGION)) {
    if ($env:BUILDKITE_ORGANIZATION_SLUG -eq "chef") { $env:AWS_REGION = "us-west-2" }
    else { $env:AWS_REGION = "us-west-1" }
  }
  if ([string]::IsNullOrEmpty($env:AWS_DEFAULT_REGION)) { $env:AWS_DEFAULT_REGION = $env:AWS_REGION }
}

function Set-AwsCredsFromEc2MetadataIfNeeded {
  if (($env:BUILDKITE_STEP_KEY -ne "build-windows-2019") -or ($env:BUILDKITE_ORGANIZATION_SLUG -notmatch 'chef(-canary)?$')) { return }
  if (Test-HasAwsCreds) { return }

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

  $stderrFile = Join-Path $env:TEMP ("aws-stderr-{0}.log" -f ([guid]::NewGuid().ToString()))
  try {
    $value = & aws @args 2> $stderrFile
    $code = $LASTEXITCODE

    if ($code -ne 0) {
      if (Test-Path $stderrFile) {
        $errText = Get-Content $stderrFile -Raw
        if (-not [string]::IsNullOrWhiteSpace($errText)) {
          $errText.TrimEnd("`r","`n").Split("`n") | ForEach-Object { Write-Info $_ }
        }
      }
      throw "Failed to read SSM parameter '$Name' (region=$Region). AWS credentials are missing/invalid OR IAM policy denies access."
    }

    return ($value | Out-String).Trim()
  }
  finally {
    Remove-Item -Force $stderrFile -ErrorAction SilentlyContinue
  }
}

# ---- Main flow ----

try { docker ps *> $null } catch { }

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

Write-Info "Fetching origin/main"
Invoke-GitSafe -Args @("fetch", "origin", "main")
Invoke-GitSafe -Args @("fetch", "--tags", "--force")

# NOTE: leaving your rebase logic out here; add it back once git stderr handling is stable on the agent.
# (The current failure is happening during git fetch already.)

# ---- SSM-derived env vars ----
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

  $env:GIT_TERMINAL_PROMPT = "0"

  if ([string]::IsNullOrEmpty($env:OMNIBUS_SUBMODULE_CONFIG_PRIVATE)) {
    $env:OMNIBUS_SUBMODULE_CONFIG_PRIVATE = $env:GITHUB_TOKEN
  }
}