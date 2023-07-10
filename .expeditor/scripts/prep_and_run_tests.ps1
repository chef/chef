param(
    # The test type ot be run (unit, integration or functional)
    [Parameter(Position=0)][String]$TestType
)

# This is temporary until we get Choco 2.x working great
function install_choco{
    Set-ExecutionPolicy Bypass -Scope Process -Force;
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
  }
  $result = Invoke-Expression -Command "choco --version"
  if(($null -ne $result ) -and ($result -lt "2.0.0"))
    {
      Remove-Item -path $env:ChocolateyInstall -Recurse -Force
      Remove-Item env:ChocolateyInstall
      if(Test-Path env:ChocolateyVersion){
        Remove-Item env:ChocolateyVersion
      }
      $env:ChocolateyVersion = "2.1.0"
      install_choco
  }
# End Choco 2 changes

. { Invoke-WebRequest -useb https://omnitruck.chef.io/chef/install.ps1 } | Invoke-Expression; install -channel "current" -project "chef-foundation" -v $CHEF_FOUNDATION_VERSION
$env:Path = 'C:\Program Files\Git\mingw64\bin;C:\Program Files\Git\usr\bin;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Windows\System32\OpenSSH\;C:\ProgramData\chocolatey\bin;C:\Program Files (x86)\Windows Kits\8.1\Windows Performance Toolkit\;C:\Program Files\Git\cmd;C:\Users\ContainerAdministrator\AppData\Local\Microsoft\WindowsApps;C:\opscode\chef\bin;C:\opscode\chef\embedded\bin'

if ($TestType -eq 'Functional') {
    winrm quickconfig -q
}

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