$ErrorActionPreference = "Stop"

# Only execute in the verify pipeline
if ($env:BUILDKITE_PIPELINE_NAME -notmatch '(verify|validate/(release|adhoc|canary))$') { exit 0 }

# Only for build steps that need omnibus-private access
if (($env:BUILDKITE_STEP_KEY -match '^build-.*') -and ($env:BUILDKITE_ORGANIZATION_SLUG -ne 'chef-oss')) {

  # Match your region logic
  if ([string]::IsNullOrEmpty($env:AWS_REGION)) {
    if ($env:BUILDKITE_ORGANIZATION_SLUG -eq 'chef') { $env:AWS_REGION = 'us-west-2' } else { $env:AWS_REGION = 'us-west-1' }
  }

  $env:GITHUB_TOKEN = (aws ssm get-parameter `
    --name "buildkite-github-clone-only-token" `
    --with-decryption `
    --query Parameter.Value `
    --output text `
    --region $env:AWS_REGION).Trim()

  if ([string]::IsNullOrEmpty($env:GITHUB_TOKEN)) {
    throw "GITHUB_TOKEN could not be loaded from SSM."
  }

  # Prevent git from hanging on prompts
  $env:GIT_TERMINAL_PROMPT = "0"
}
