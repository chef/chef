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

 function installChoco {
    $env:chocolateyVersion = "1.4.0"
    if (!(Test-Path "$($env:ProgramData)\chocolatey\choco.exe")) {
        Write-Output "Chocolatey is not installed, proceeding to install"
            try {
                write-output "installing in 3..2..1.."
                Set-ExecutionPolicy Bypass -Scope Process -Force
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
            }

            catch {
                  Write-Error $_.Exception.Message
            }
    }

    else {
        Write-Output "Chocolatey is already installed"
    }
  }

  installChoco

# Make `Update-SessionEnvironment` available
Write-Output "Importing the Chocolatey profile module"
$ChocolateyInstall = Convert-Path "$((Get-Command choco).path)\..\.."
Import-Module "$ChocolateyInstall\helpers\chocolateyProfile.psm1"

Write-Output "Refreshing the current PowerShell session's environment"
Update-SessionEnvironment

# Install Ruby using Chocolatey
if (-not (Get-Command ruby.exe -ErrorAction SilentlyContinue)) {
    Write-Output "Ruby not found. Installing Ruby..."
    choco install ruby -y
} else {
    Write-Output "Ruby is already installed."
}

    #check ruby version
    Write-Host "Checking Ruby version"
    ruby --version
    # check gem version
    Write-Host "Checking gem version"
    gem --version
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
