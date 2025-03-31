param (
    [string]$chefVersion
)

# Define the repository URL
$repoUrl = "https://github.com/chef/chocolatey-packages"

# Check if the chocolatey-packages folder exists as a sibling to the root of the current project
$projectRoot = (Get-Location).Parent.FullName
$chocoPackagesPath = Join-Path $projectRoot "chocolatey-packages"

if (-Not (Test-Path $chocoPackagesPath)) {
    # Clone the repository if the folder doesn't exist
    git clone $repoUrl $chocoPackagesPath
}

cd $chocoPackagesPath

# Get the SHA256 checksum for the specified Chef version
$checksumUrl = "https://omnitruck.chef.io/current/chef/packages?v=$chefVersion"
$checksum = (Invoke-RestMethod -Uri $checksumUrl).windows.sha256

# Update the version and checksum in the nuspec and ps1 files
(Get-Content .\chef\chef.nuspec) -replace '(<version>)[^<]+(</version>)', "`$1$chefVersion`$2" | Set-Content .\chef\chef.nuspec
(Get-Content .\chef\chocolateyinstall.ps1) -replace '(checksum = ")[^"]+(")', "`$1$checksum`$2" | Set-Content .\chef\chocolateyinstall.ps1

# Pack the Chocolatey package
choco pack .\chef\chef.nuspec

# Get the API key from the user
$apiKey = Read-Host -Prompt "Enter Chocolatey API key"

# Push the package to Chocolatey
choco push .\chef.$chefVersion.nupkg --api-key $apiKey --source=https://push.chocolatey.org/

# Clean up
cd ..
Remove-Item -Recurse -Force $chocoPackagesPath
