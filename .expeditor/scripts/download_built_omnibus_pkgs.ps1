$ErrorActionPreference = "Stop"

Write-Host "--- Installing package from BuildKite"
buildkite-agent artifact download "omnibus-ruby\chef\pkg\*.msi" . --step "${Env:OMNIBUS_BUILDER_KEY}"

if (Test-Path "omnibus-ruby\chef\pkg") {
    $package_file = (Get-ChildItem omnibus-ruby\chef\pkg\ -Filter "*.msi" | Select-Object -First 1).FullName
} else {
    Write-Error "Downloaded artifact directory not found"
    exit 1
}

Write-Output "--- Installing $package_file"
Start-Process "$package_file" /quiet -Wait

Write-Output "--- Deleting $package_file"
Remove-Item -Force "$package_file" -ErrorAction SilentlyContinue