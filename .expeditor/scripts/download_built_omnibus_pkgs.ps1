$ErrorActionPreference = "Stop"

Write-Host "--- Installing package from BuildKite"
buildkite-agent artifact download "pkg\*.msi" . --step "${Env:OMNIBUS_BUILDER_KEY}"
$package_file = (Get-ChildItem pkg -Filter "*.msi").FullName

Write-Host "--- Setting CHEF_LICENSE_SERVER environment variable"
# Read the CHEF_LICENSE_SERVER value from chef_license_server_url.txt
$CHEF_LICENSE_SERVER = Get-Content -Path "$PSScriptRoot/chef_license_server_url.txt"
# Set the environment variable
$env:CHEF_LICENSE_SERVER = $CHEF_LICENSE_SERVER
# Output the CHEF_LICENSE_SERVER environment variable
Write-Host "--- CHEF_LICENSE_SERVER URL: $env:CHEF_LICENSE_SERVER"

Write-Output "--- Installing $package_file"
Start-Process "$package_file" /quiet -Wait

Write-Output "--- Deleting $package_file"
Remove-Item -Force "$package_file" -ErrorAction SilentlyContinue