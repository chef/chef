param(
    # The test type ot be run (unit, integration or functional)
    [Parameter(Position=0)][String]$TestType
)

$env:Path = 'C:\Program Files\Git\mingw64\bin;C:\Program Files\Git\usr\bin;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Windows\System32\OpenSSH\;C:\ProgramData\chocolatey\bin;C:\Program Files (x86)\Windows Kits\8.1\Windows Performance Toolkit\;C:\Program Files\Git\cmd;C:\Users\ContainerAdministrator\AppData\Local\Microsoft\WindowsApps;'

if ($TestType -eq 'Functional') {
    winrm quickconfig -q
}

# Write-Output "--- Checking the Chocolatey version"
# $installed_version = Get-ItemProperty "${env:ChocolateyInstall}/choco.exe" | select-object -expandproperty versioninfo| select-object -expandproperty productversion
# if(-not ($installed_version -match ('^2'))){
#     Write-Output "--- Now Upgrading Choco"
#     try {
#         choco feature enable -n=allowGlobalConfirmation
#         choco upgrade chocolatey
#     }
#     catch {
#         Write-Output "Upgrade Failed"
#         Write-Output $_
#         <#Do this if a terminating exception happens#>
#     }

# }

try {
    $buildkiteJSONData = Get-Content -Path ".buildkite-platform.json" -Raw | ConvertFrom-Json
    $ruby_version = $buildkiteJSONData.ruby_version
    
    Write-Output "--- Fetching ruby package at $ruby_version.*"
    # find out a matching version. e.g. 3.1.6 will match 3.1.6.1. otherwise, choco fails because it doesn't find an exact match
    # for 3.1.6
    $allVersions = choco search ruby --exact --all | foreach Split "ruby " | Where-Object { $_ -match "^$ruby_version" }
    Write-Output "Found ruby versions: $allVersions"
    if ($allVersions.Count -eq 0) {
        throw "No version found matching ruby $ruby_version.*"
    }

    $latestMatchingVersion = $allVersions | Sort-Object -Descending | Select-Object -First 1 

    Write-Output "--- Installing ruby version $latestMatchingVersion"
    choco install ruby --version=$latestMatchingVersion -y 

    # $installedVersion = (choco list -lo ruby | Select-String -Pattern "ruby (\d+\.\d+)").Matches.Groups[1].Value
    $installedVersion = (echo $ruby_version | Select-String -Pattern "(\d+\.\d+)").Matches.Groups[1].Value
    $installedVersion = $installedVersion -replace '\.', ''
    $env:Path += ";C:\tools\ruby$installedVersion\bin"

    ruby -v

    $bundler_version = $buildkiteJSONData.bundle_version

    Write-Output "--- Installing bundler $bundler_version"
    gem install bundler -v $bundler_version
    bundle -v

} catch {
    Write-Output "Error setting up ruby environment"
    Write-Output $_
}

Write-Output "--- Installing OpenSSL via Chocolatey"
choco install openssl --version=3.1.1 -y
$env:Path = "C:\Program Files\OpenSSL-Win64\bin;" + $env:Path

$openssl_dir = (Get-Item (Get-Command openssl).Source).Directory.Parent.FullName
$env:SSL_CERT_FILE = "$openssl_dir\ssl\cert.pem"

Write-Output "Configure bundle to build openssl gem with $openssl_dir"
bundle config build.openssl --with-openssl-dir=$openssl_dir
gem install openssl:3.2.0 -- --with-openssl-dir=$openssl_dir --with-openssl-include="$openssl_dir/include" --with-openssl-lib="$openssl_dir/lib"

Write-Output "--- Running Chef bundle install"
bundle install --jobs=3 --retry=3 

switch ($TestType) {
    "Unit"          {[string[]]$RakeTest = 'spec:unit','component_specs'; break}
    "Integration"   {[string[]]$RakeTest = "spec:integration"; break}
    "Functional"    {[string[]]$RakeTest = "spec:functional"; break}
    default         {throw "TestType $TestType not valid"}
}

foreach($test in $RakeTest) {
    Write-Output "--- Chef $test run"
    bundle exec rake $test
    if (-not $?) { throw "Chef $test tests failed" }
}
