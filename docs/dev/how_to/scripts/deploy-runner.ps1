#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy a GitHub Actions runner to Azure using Bicep (Windows or Linux)

.DESCRIPTION
    This script deploys a VM to Azure configured as a GitHub Actions self-hosted runner
    using Bicep templates. Works from any platform (Windows, macOS, Linux).

.PARAMETER RunnerType
    Type of runner to deploy: 'windows' or 'linux'

.PARAMETER ResourceGroupName
    Name of the Azure resource group (will be created if it doesn't exist)

.PARAMETER Location
    Azure region for deployment (default: eastus)

.PARAMETER VmName
    Name of the virtual machine

.PARAMETER VmSize
    Azure VM size (default varies by runner type)

.PARAMETER AdminUsername
    Admin username for the VM (default: runneradmin)

.PARAMETER AdminPassword
    Admin password for Windows VM (will be prompted if not provided)

.PARAMETER SshPublicKey
    Path to SSH public key file for Linux VM (will be prompted if not provided)

.PARAMETER GithubRepoUrl
    GitHub repository URL (e.g., https://github.com/chef/chef)

.PARAMETER GithubToken
    GitHub registration token (will be prompted if not provided)

.PARAMETER RunnerName
    Name for the GitHub runner (defaults to VM name)

.PARAMETER RunnerLabels
    Comma-separated labels for the runner (defaults vary by runner type)

.PARAMETER RunnerVersion
    GitHub Actions runner version (default: 2.317.0 for Windows, latest for Linux)

.EXAMPLE
    .\deploy-runner.ps1 -RunnerType windows -ResourceGroupName "github-runners-rg" -GithubRepoUrl "https://github.com/chef/chef"

.EXAMPLE
    .\deploy-runner.ps1 -RunnerType linux -ResourceGroupName "rg-runners" -SshPublicKey "~/.ssh/id_rsa.pub" -GithubRepoUrl "https://github.com/chef/chef"

.EXAMPLE
    .\deploy-runner.ps1 -RunnerType windows -ResourceGroupName "rg" -VmName "win-runner-01" -Location "westus2" -GithubRepoUrl "https://github.com/chef/chef"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('windows', 'linux')]
    [string]$RunnerType,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter()]
    [string]$Location = "eastus",

    [Parameter()]
    [string]$VmName = "",

    [Parameter()]
    [string]$VmSize = "",

    [Parameter()]
    [string]$AdminUsername = "runneradmin",

    [Parameter()]
    [SecureString]$AdminPassword,

    [Parameter()]
    [string]$SshPublicKey = "",

    [Parameter(Mandatory = $true)]
    [string]$GithubRepoUrl,

    [Parameter()]
    [SecureString]$GithubToken,

    [Parameter()]
    [string]$RunnerName = "",

    [Parameter()]
    [string]$RunnerLabels = "",

    [Parameter()]
    [string]$RunnerVersion = ""
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "GitHub Runner Azure Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Set defaults based on runner type
if ([string]::IsNullOrWhiteSpace($VmName)) {
    $VmName = "github-runner-$RunnerType"
}

if ([string]::IsNullOrWhiteSpace($VmSize)) {
    if ($RunnerType -eq 'windows') {
        $VmSize = "Standard_D2s_v3"
    } else {
        $VmSize = "Standard_B2s"
    }
}

if ([string]::IsNullOrWhiteSpace($RunnerLabels)) {
    if ($RunnerType -eq 'windows') {
        $RunnerLabels = "windows,self-hosted,azure"
    } else {
        $RunnerLabels = "linux,self-hosted,azure,ubuntu"
    }
}

if ([string]::IsNullOrWhiteSpace($RunnerVersion)) {
    if ($RunnerType -eq 'windows') {
        $RunnerVersion = "2.317.0"
    } else {
        $RunnerVersion = "latest"
    }
}

if ([string]::IsNullOrWhiteSpace($RunnerName)) {
    $RunnerName = $VmName
}

# Check if Azure CLI is installed
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Error "Azure CLI is not installed. Please install it from https://aka.ms/installazurecli"
    exit 1
}

# Check if logged in to Azure
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "Not logged in to Azure. Please login..." -ForegroundColor Yellow
    az login
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Azure login failed"
        exit 1
    }
    $account = az account show | ConvertFrom-Json
}

Write-Host "Using Azure subscription: $($account.name)" -ForegroundColor Green
Write-Host ""

# Runner type specific validation and prompts
if ($RunnerType -eq 'windows') {
    # Prompt for admin password if not provided
    if (-not $AdminPassword) {
        Write-Host "Admin password is required for the Windows VM" -ForegroundColor Yellow
        $AdminPassword = Read-Host "Enter admin password" -AsSecureString
        $confirmPassword = Read-Host "Confirm admin password" -AsSecureString

        $pwd1 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword)
        )
        $pwd2 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($confirmPassword)
        )

        if ($pwd1 -ne $pwd2) {
            Write-Error "Passwords do not match"
            exit 1
        }
    }
} else {
    # Linux - need SSH key
    if ([string]::IsNullOrWhiteSpace($SshPublicKey)) {
        $defaultKeyPath = Join-Path $env:HOME ".ssh/id_rsa.pub"
        if (Test-Path $defaultKeyPath) {
            Write-Host "Found SSH key at: $defaultKeyPath" -ForegroundColor Yellow
            $usDefault = Read-Host "Use this key? (Y/N)"
            if ($usDefault -eq 'Y' -or $usDefault -eq 'y') {
                $SshPublicKey = $defaultKeyPath
            } else {
                $SshPublicKey = Read-Host "Enter path to SSH public key"
            }
        } else {
            Write-Host "SSH public key is required for Linux VM" -ForegroundColor Yellow
            $SshPublicKey = Read-Host "Enter path to SSH public key file"
        }
    }

    # Expand path if it starts with ~
    if ($SshPublicKey.StartsWith("~")) {
        $SshPublicKey = $SshPublicKey -replace "^~", $env:HOME
    }

    if (-not (Test-Path $SshPublicKey)) {
        Write-Error "SSH key file not found: $SshPublicKey"
        exit 1
    }
}

# Prompt for GitHub token if not provided
if (-not $GithubToken) {
    Write-Host ""
    Write-Host "GitHub registration token is required" -ForegroundColor Yellow
    Write-Host "Get it from: $GithubRepoUrl/settings/actions/runners" -ForegroundColor Cyan
    Write-Host "Or use: gh api --method POST /repos/OWNER/REPO/actions/runners/registration-token" -ForegroundColor Cyan
    Write-Host ""
    $GithubToken = Read-Host "Enter GitHub registration token" -AsSecureString
}

# Display configuration
Write-Host "Deployment Configuration:" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host "Runner Type: $RunnerType" -ForegroundColor White
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "Location: $Location" -ForegroundColor White
Write-Host "VM Name: $VmName" -ForegroundColor White
Write-Host "VM Size: $VmSize" -ForegroundColor White
Write-Host "Admin Username: $AdminUsername" -ForegroundColor White
if ($RunnerType -eq 'linux') {
    Write-Host "SSH Key: $SshPublicKey" -ForegroundColor White
}
Write-Host "GitHub Repository: $GithubRepoUrl" -ForegroundColor White
Write-Host "Runner Name: $RunnerName" -ForegroundColor White
Write-Host "Runner Labels: $RunnerLabels" -ForegroundColor White
Write-Host "Runner Version: $RunnerVersion" -ForegroundColor White
Write-Host ""

# Confirm deployment
$confirm = Read-Host "Proceed with deployment? (Y/N)"
if ($confirm -ne 'Y' -and $confirm -ne 'y') {
    Write-Host "Deployment cancelled" -ForegroundColor Yellow
    exit 0
}

# Create resource group if it doesn't exist
Write-Host ""
Write-Host "Checking resource group..." -ForegroundColor Yellow
$rgExists = az group exists --name $ResourceGroupName | ConvertFrom-Json
if (-not $rgExists) {
    Write-Host "Creating resource group: $ResourceGroupName" -ForegroundColor Yellow
    az group create --name $ResourceGroupName --location $Location | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create resource group"
        exit 1
    }
    Write-Host "Resource group created successfully" -ForegroundColor Green
} else {
    Write-Host "Resource group already exists" -ForegroundColor Green
}

# Find the Bicep template
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$bicepTemplate = Join-Path $scriptDir "templates" "github-runner-$RunnerType.bicep"

if (-not (Test-Path $bicepTemplate)) {
    Write-Error "Bicep template not found: $bicepTemplate"
    exit 1
}

# Prepare parameters based on runner type
$deploymentName = "github-runner-$(Get-Date -Format 'yyyyMMddHHmmss')"
$parameters = @(
    "vmName=$VmName",
    "location=$Location",
    "vmSize=$VmSize",
    "adminUsername=$AdminUsername",
    "githubRepoUrl=$GithubRepoUrl",
    "runnerName=$RunnerName",
    "runnerLabels=$RunnerLabels",
    "runnerVersion=$RunnerVersion"
)

if ($RunnerType -eq 'windows') {
    $adminPasswordText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword)
    )
    $parameters += "adminPassword=$adminPasswordText"
} else {
    $sshKeyData = Get-Content $SshPublicKey -Raw
    $parameters += "sshPublicKey=$sshKeyData"
}

$githubTokenText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($GithubToken)
)
$parameters += "githubRegistrationToken=$githubTokenText"

# Deploy the Bicep template
Write-Host ""
Write-Host "Deploying Bicep template..." -ForegroundColor Yellow
Write-Host "This may take several minutes..." -ForegroundColor Yellow
Write-Host ""

az deployment group create `
    --name $deploymentName `
    --resource-group $ResourceGroupName `
    --template-file $bicepTemplate `
    --parameters $parameters

if ($LASTEXITCODE -ne 0) {
    Write-Error "Deployment failed"
    exit 1
}

# Get deployment outputs
Write-Host ""
Write-Host "Retrieving deployment outputs..." -ForegroundColor Yellow
$outputs = az deployment group show `
    --name $deploymentName `
    --resource-group $ResourceGroupName `
    --query properties.outputs `
    | ConvertFrom-Json

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "VM Name: $($outputs.vmName.value)" -ForegroundColor White
Write-Host "Public IP: $($outputs.publicIpAddress.value)" -ForegroundColor White
Write-Host "Admin Username: $($outputs.adminUsername.value)" -ForegroundColor White
Write-Host "Runner Name: $($outputs.runnerName.value)" -ForegroundColor White
Write-Host ""

if ($RunnerType -eq 'windows') {
    Write-Host "RDP Connection: mstsc /v:$($outputs.publicIpAddress.value)" -ForegroundColor Cyan
} else {
    Write-Host "SSH Connection: $($outputs.sshCommand.value)" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Check runner status at: $GithubRepoUrl/settings/actions/runners" -ForegroundColor Yellow
Write-Host ""
Write-Host "Note: The runner installation may take a few more minutes to complete." -ForegroundColor Yellow
Write-Host "Check the custom script extension status in the Azure portal." -ForegroundColor Yellow
Write-Host ""
