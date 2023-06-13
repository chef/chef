Write-Output "--- system details"
$Properties = 'Caption', 'CSName', 'Version', 'BuildType', 'OSArchitecture'
Get-CimInstance Win32_OperatingSystem | Select-Object $Properties | Format-Table -AutoSize

# Beginning of Choco 2.0 workaround
# Choco 2.0 has shipped and changes the behavior of the choco 'list' command. Thhe changes here
# put us back to the behavior of choco 1.4.0. This is a long term problem
# for us because we have a lot of tests that depend on the old behavior. We need to
# update them for choco 2.0

$VerbosePreference = 'Continue'
if (-not $env:ChocolateyInstall) {
    $message = @(
        "The ChocolateyInstall environment variable was not found."
        "Chocolatey is not detected as installed. Nothing to do."
    ) -join "`n"

    Write-Warning $message
    return
}

if (-not (Test-Path $env:ChocolateyInstall)) {
    $message = @(
        "No Chocolatey installation detected at '$env:ChocolateyInstall'."
        "Nothing to do."
    ) -join "`n"

    Write-Warning $message
    return
}

<#
    Using the .NET registry calls is necessary here in order to preserve environment variables embedded in PATH values;
    Powershell's registry provider doesn't provide a method of preserving variable references, and we don't want to
    accidentally overwrite them with absolute path values. Where the registry allows us to see "%SystemRoot%" in a PATH
    entry, PowerShell's registry provider only sees "C:\Windows", for example.
#>
$userKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment',$true)
$userPath = $userKey.GetValue('PATH', [string]::Empty, 'DoNotExpandEnvironmentNames').ToString()

$machineKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\ControlSet001\Control\Session Manager\Environment\',$true)
$machinePath = $machineKey.GetValue('PATH', [string]::Empty, 'DoNotExpandEnvironmentNames').ToString()

$backupPATHs = @(
    "User PATH: $userPath"
    "Machine PATH: $machinePath"
)
$backupFile = "C:\PATH_backups_ChocolateyUninstall.txt"
$backupPATHs | Set-Content -Path $backupFile -Encoding UTF8 -Force

$warningMessage = @"
    This could cause issues after reboot where nothing is found if something goes wrong.
    In that case, look at the backup file for the original PATH values in '$backupFile'.
"@

if ($userPath -like "*$env:ChocolateyInstall*") {
    Write-Verbose "Chocolatey Install location found in User Path. Removing..."
    Write-Warning $warningMessage

    $newUserPATH = @(
        $userPath -split [System.IO.Path]::PathSeparator |
            Where-Object { $_ -and $_ -ne "$env:ChocolateyInstall\bin" }
    ) -join [System.IO.Path]::PathSeparator

    # NEVER use [Environment]::SetEnvironmentVariable() for PATH values; see https://github.com/dotnet/corefx/issues/36449
    # This issue exists in ALL released versions of .NET and .NET Core as of 12/19/2019
    $userKey.SetValue('PATH', $newUserPATH, 'ExpandString')
}

if ($machinePath -like "*$env:ChocolateyInstall*") {
    Write-Verbose "Chocolatey Install location found in Machine Path. Removing..."
    Write-Warning $warningMessage

    $newMachinePATH = @(
        $machinePath -split [System.IO.Path]::PathSeparator |
            Where-Object { $_ -and $_ -ne "$env:ChocolateyInstall\bin" }
    ) -join [System.IO.Path]::PathSeparator

    # NEVER use [Environment]::SetEnvironmentVariable() for PATH values; see https://github.com/dotnet/corefx/issues/36449
    # This issue exists in ALL released versions of .NET and .NET Core as of 12/19/2019
    $machineKey.SetValue('PATH', $newMachinePATH, 'ExpandString')
}

# Adapt for any services running in subfolders of ChocolateyInstall
$agentService = Get-Service -Name chocolatey-agent -ErrorAction SilentlyContinue
if ($agentService -and $agentService.Status -eq 'Running') {
    $agentService.Stop()
}
# TODO: add other services here

Remove-Item -Path $env:ChocolateyInstall -Recurse -Force 

'ChocolateyInstall', 'ChocolateyLastPathUpdate' | ForEach-Object {
    foreach ($scope in 'User', 'Machine') {
        [Environment]::SetEnvironmentVariable($_, [string]::Empty, $scope)
    }
}

$machineKey.Close()
$userKey.Close()

$env:chocolateyVersion = "1.4.0"
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
# end of choco 2.0 workaround

# chocolatey functional tests fail so delete the chocolatey binary to avoid triggering them
Remove-Item -Path C:\ProgramData\chocolatey\bin\choco.exe -ErrorAction SilentlyContinue

$ErrorActionPreference = 'Stop'

Write-Output "--- Enable Ruby 3.0"

# Ruby is not installed at this point for some reason. Installing it now
$pkg_version="3.0.3"
$pkg_revision="1"
$pkg_source="https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-${pkg_version}-${pkg_revision}/rubyinstaller-devkit-${pkg_version}-${pkg_revision}-x64.exe"

if (Get-Command Ruby -ErrorAction SilentlyContinue){
    $old_version = Ruby --version
  }
else {
    $old_version = $null
}
  
if(-not($old_version -match "3.0")){
    Write-Output "Downloading Ruby + DevKit";
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
    $package_destination = "$env:temp\rubyinstaller-devkit-$pkg_version-$pkg_revision-x64.exe"
    (New-Object System.Net.WebClient).DownloadFile($pkg_source, $package_destination);
    Write-Output "`rDid the file download?"
    Test-Path $package_destination
    Write-Output "`rInstalling Ruby + DevKit";
    Start-Process $package_destination -ArgumentList "/verysilent /dir=C:\ruby30" -Wait ;
    Write-Output "Cleaning up installation";
    Remove-Item $package_destination -Force;
}
  
Write-Output "Register Installed Ruby Version 3.0 With Uru"
Start-Process "uru_rt.exe" -ArgumentList 'admin add C:\ruby30\bin' -Wait
uru 30
if (-not $?) { throw "Can't Activate Ruby. Did Uru Registration Succeed?" }
ruby -v
if (-not $?) { throw "Can't run Ruby. Is it installed?" }

Write-Output "--- configure winrm"
winrm quickconfig -q

Write-Output "--- bundle install"
bundle config set --local without "omnibus_package"
bundle install --jobs=3 --retry=3
if (-not $?) { throw "Unable to install gem dependencies" }

Write-Output "+++ bundle exec rake spec:functional"
bundle exec rake spec:functional SPEC_OPTS="--format documentation"
if (-not $?) { throw "Chef functional specs failing." }
