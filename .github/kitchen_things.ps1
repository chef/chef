. { Invoke-WebRequest -useb https://omnitruck.chef.io/install.ps1 } | Invoke-Expression; Install-Project -project chef -channel stable -v 17
$env:PATH = "C:\opscode\chef\bin;C:\opscode\chef\embedded\bin;" + $env:PATH
chef-client -v
ohai -v
rake --version
bundle -v

# Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
# choco install git

$env:PATH = "C:\opscode\chef\bin;C:\opscode\chef\embedded\bin;" + $env:PATH
$env:OHAI_VERSION = ( Select-String -Path .\Gemfile.lock -Pattern '(?<=ohai \()\d.*(?=\))' | ForEach-Object { $_.Matches[0].Value } )

# The chef-client installer does not put the file 'ansidecl.h' down in the correct location
# This leads to failures during testing. Moving that file to its correct position here.
# Another example of 'bad' that needs to be corrected
$output = gci -path C:\opscode\ -file ansidecl.h -Recurse
$target_path = $($output.Directory.Parent.FullName + "\x86_64-w64-mingw32\include")
Move-Item -Path $output.FullName -Destination $target_path

gem install appbundler appbundle-updater --no-doc
If ($lastexitcode -ne 0) { Exit $lastexitcode }

#appbundle-updater chef chef $env:GITHUB_SHA --tarball --github $env:GITHUB_REPOSITORY
appbundle-updater chef chef tp/jfm/chef17-depends-update --github chef/chef
If ($lastexitcode -ne 0) { Exit $lastexitcode }

Write-Output "Installed Chef / Ohai release:"
chef-client -v
If ($lastexitcode -ne 0) { Exit $lastexitcode }

ohai -v
If ($lastexitcode -ne 0) { Exit $lastexitcode }
