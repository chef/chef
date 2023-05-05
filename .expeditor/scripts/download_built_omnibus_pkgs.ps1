$ErrorActionPreference = "Stop"

Write-Host "--- Installing package from BuildKite"
buildkite-agent artifact download "pkg\*.msi" . --step "${Env:OMNIBUS_BUILDER_KEY}"
$package_file = (Get-ChildItem pkg -Filter "*.msi").FullName 

Write-Output "--- Installing $package_file"
Start-Process "$package_file" /quiet -Wait

Write-Output "--- Deleting $package_file"
Remove-Item -Force "$package_file" -ErrorAction SilentlyContinue