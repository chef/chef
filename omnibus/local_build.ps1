if (-Not (Get-Command choco -ErrorAction SilentlyContinue))
{
# install Chrome
  $LocalTempDir = $env:TEMP; $ChromeInstaller = "ChromeInstaller.exe"; (new-object System.Net.WebClient).DownloadFile('http://dl.google.com/chrome/install/375.126/chrome_installer.exe', "$LocalTempDir\$ChromeInstaller"); & "$LocalTempDir\$ChromeInstaller" /silent /install; $Process2Monitor =  "ChromeInstaller"; Do { $ProcessesFound = Get-Process | ?{$Process2Monitor -contains $_.Name} | Select-Object -ExpandProperty Name; If ($ProcessesFound) { "Still running: $($ProcessesFound -join ', ')" | Write-Host; Start-Sleep -Seconds 2 } else { rm "$LocalTempDir\$ChromeInstaller" -ErrorAction SilentlyContinue -Verbose } } Until (!$ProcessesFound)


# Install Chocolately
  Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Refresh PATH
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

}

if (-Not (Get-Command git -ErrorAction SilentlyContinue))
{
# Install git
  choco install git

# Refresh PATH
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

if (-Not (Test-Path "C:\Projects"))
{
  mkdir c:\projects
}
cd c:\projects

if (-Not (Test-Path "C:\Ruby31-x64"))
{
  Invoke-WebRequest -Uri "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.1.2-1/rubyinstaller-devkit-3.1.2-1-x64.exe" -OutFile "rubyinstaller-devkit-3.1.2-x64.exe"
  .\rubyinstaller-devkit-3.1.2-x64.exe
}

# install 7-Zip and add to path
# `mkdir c:\ruby31-x64\msys64\tmp`
#
if (-Not (Get-Command heat.exe -ErrorAction SilentlyContinue))
{
  choco install dotnet3.5
  Invoke-WebRequest -Uri "https://github.com/wixtoolset/wix3/releases/download/wix3112rtm/wix311.exe" -OutFile "wix311.exe"
  .\wix311.exe
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

}

if (-Not (Test-Path "C:\projects\chef"))
{
  # Set up dev work directory
  git clone https://github.com/chef/chef
  cd chef
}

git fetch origin
git checkout tp/debug-fips-locally
git pull

# omnibus/omnibus.rb looking for x64 or x86 or defaults to x86
$env:MSYSTEM="UCRT64"
$ENV:MSYS2_INSTALL_DIR="C:/Ruby31-x64/msys64"
$env:OMNIBUS_WINDOWS_ARCH = "x64"
$env:OMNIBUS_FIPS_MODE="true"
$mePath=$env:PATH
$env:PATH="C:\Program Files\7-Zip;C:\Ruby31-x64\msys64\usr\bin;C:\Ruby31-x64\msys64\ucrt64\bin;$env:MSYS2_INSTALL_DIR\usr\bin;C:\Program Files\git\bin;$mePath"

$env:OMNIBUS_GITHUB_BRANCH="tp/debug-fips-locally"
$env:OMNIBUS_SOFTWARE_GITHUB_BRANCH="tp/debug-fips-locally"

cd omnibus
bundle config set --local without development
bundle update --conservative omnibus
bundle update --conservative omnibus-software
bundle install
pushd ..
bundle install
popd
mkdir $env:MSYS2_INSTALL_DIR\tmp
bundle exec omnibus build chef
