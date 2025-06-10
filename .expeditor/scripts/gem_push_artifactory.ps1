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

# powershell -File "./.expeditor/scripts/ensure-minimum-viable-hab.ps1"
# if (-not $?) { throw "Could not ensure the minimum hab version required is installed." }
# $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")


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

    # Build gems via habitat
    Write-Host "Building gems via habitat"
    hab pkg build -D .
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to build package" -ForegroundColor Yellow
        throw "Failed to build habitat package"
    }

    # Install ruby via winget
    Write-Host "Installing Ruby via winget"
    winget install --id Ruby.Ruby --version 3.4.2 --source winget --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install Ruby"
    }
    Write-Host "Ruby installation completed successfully" -ForegroundColor Green
    # Add Ruby to PATH
    $rubyPath = "C:\Program Files\Ruby 3.4.2\bin"
    $env:Path += ";$rubyPath"
    Write-Host "Ruby path added to environment variables" -ForegroundColor Green
    # Verify Ruby installation
    Write-Host "Verifying Ruby installation"
    ruby --version
    if ($LASTEXITCODE -ne 0) {
        throw "Ruby verification failed"
    }
    Write-Host "Ruby verification completed successfully" -ForegroundColor Green
    # Install bundler gem
    Write-Host "Installing bundler gem"
    gem install bundler --no-document
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install bundler gem"
    }
    Write-Host "Bundler gem installation completed successfully" -ForegroundColor Green

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
