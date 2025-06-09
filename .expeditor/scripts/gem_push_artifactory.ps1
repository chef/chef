$ErrorActionPreference = "Stop"

# Set environment variables
$env:HAB_ORIGIN = "chef"
$env:CHEF_LICENSE = "accept-no-persist"
$env:HAB_LICENSE = "accept-no-persist"
$env:HAB_NONINTERACTIVE = "true"
$env:HAB_BLDR_CHANNEL = "LTS-2024"
$env:PROJECT_NAME = "chef"
$env:ARTIFACTORY_ENDPOINT = "https://artifactory-internal.ps.chef.co/artifactory"
$env:ARTIFACTORY_USERNAME = "buildkite"

Write-Output "installing AWS CLI ..."
# Install AWS CLI
$awsCliPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
if (-Not (Test-Path $awsCliPath)) {
    $awsInstallerUrl = "https://awscli.amazonaws.com/AWSCLIV2.msi"
    $awsInstallerPath = "$env:TEMP\AWSCLIV2.msi"
    Invoke-WebRequest -Uri $awsInstallerUrl -OutFile $awsInstallerPath
    Start-Process msiexec.exe -ArgumentList "/i `"$awsInstallerPath`" /quiet /norestart" -Wait
    Remove-Item $awsInstallerPath -Force
} else {
    Write-Output "AWS CLI is already installed."
}
# Ensure AWS CLI is in the PATH
$env:PATH += ";C:\Program Files\Amazon\AWSCLIV2"
# Check if AWS CLI is installed
if (-Not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Host "AWS CLI installation failed or is not in the PATH." -ForegroundColor Red
    exit 1
}
 Write-Output "Install Chef Habitat  ..."
# Use TLS 1.2 for Windows 2016 Server and older
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-Expression "& { $(Invoke-RestMethod https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.ps1) } -Version 1.6.1243"

try {
    # Get password from AWS SSM Parameter Store
    Write-Host "Retrieving artifactory password from AWS SSM..."
    $lita_password = aws ssm get-parameter --name "artifactory-lita-password" --with-decryption --query Parameter.Value --output text --region us-west-2

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to retrieve password from AWS SSM"
    }

    # Create base64 encoded API key
    $credentials = "lita:$lita_password"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($credentials)
    $artifactory_api_key = [System.Convert]::ToBase64String($bytes)
    $env:GEM_HOST_API_KEY = "Basic $artifactory_api_key"

    # Generate origin key
    Write-Host "Generating origin key"
    hab origin key generate $env:HAB_ORIGIN

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to generate origin key"
    }
    # check hab version
    Write-Host "Checking hab version"
    hab --version
    # check hab help
    Write-Host "Checking hab help"
    hab --help
    # Build gems via habitat
    Write-Host "Building gems via habitat"
    hab pkg build -D .

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to build package" -ForegroundColor Yellow
        throw "Failed to build habitat package"
    }

    # Push gems to artifactory
    Write-Host "Push gems to artifactory"
    gem install artifactory -v 3.0.17 --no-document

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install artifactory gem"
    }

    ruby .expeditor/scripts/gem_push_artifactory.rb

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to push gems to artifactory"
    }

    Write-Host "Gem push to artifactory completed successfully" -ForegroundColor Green

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
