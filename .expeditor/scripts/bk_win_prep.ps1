echo "--- system details"
$Properties = 'Caption', 'CSName', 'Version', 'BuildType', 'OSArchitecture'
Get-CimInstance Win32_OperatingSystem | Select-Object $Properties | Format-Table -AutoSize

echo "ruby version:"
ruby -v
if (-not $?) { throw "Can't run Ruby. Is it installed?" }

echo "bundler version: "
bundle --version
if (-not $?) { throw "Can't run Bundler. Is it installed?" }

echo "--- bundle install"
bundle config set --local without omnibus_package
bundle config set --local path 'vendor/bundle'
bundle install --jobs=3 --retry=3
if (-not $?) { throw "Unable to install gem dependencies" }

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
