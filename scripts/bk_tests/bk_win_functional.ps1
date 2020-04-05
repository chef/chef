# The filename of the Ruby installer
$RubyFilename = "rubyinstaller-devkit-2.6.5-1-x64.exe"

# The sha256 of the Ruby installer (capitalized?)
$RubySHA256 = "BD2050496A149C7258ED4E2E44103756CA3A05C7328A939F0FDC97AE9616A96D"

# Where on disk to download Ruby to
$RubyPath = "$env:temp\$RubyFilename"

# Where to download Ruby from:
$RubyS3Path = "s3://public-cd-buildkite-cache/$RubyFilename"

Function DownloadRuby
{
  echo "Downloading Ruby + DevKit"
  aws s3 cp $RubyS3Path $RubyPath | Out-Null # Out-Null is a hack to wait for the process to complete

  if ($LASTEXITCODE -ne 0)
  {
    echo "aws s3 download failed: $LASTEXITCODE"
    exit $LASTEXITCODE
  }
  $DownloadedHash = (Get-FileHash $RubyPath -Algorithm SHA256).Hash
  echo "Downloaded SHA256: $DownloadedHash"
}

Function InstallRuby
{
  If (Test-Path $RubyPath) {
    echo "$RubyPath already exists"

    $ExistingRubyHash = (Get-FileHash $RubyPath -Algorithm SHA256).Hash

    echo "Verifying file SHA256 hash $ExistingRubyHash to desired hash $RubySHA256"

    If ($ExistingRubyHash -ne $RubySHA256) {
      echo "SHA256 hash mismatch, attempting to remove and re-download"
      Remove-Item $RubyPath -Force
      DownloadRuby
    } Else {
      echo "Found matching Ruby + DevKit on disk"
    }
  } Else {
    echo "No Ruby found at $RubyPath, downloading"
    DownloadRuby
  }

  echo "Installing Ruby + DevKit"
  Start-Process $RubyPath -ArgumentList '/verysilent /dir=C:\\ruby26' -Wait

  echo "Cleaning up installation"
  Remove-Item $RubyPath -Force -ErrorAction SilentlyContinue
}

echo "--- system details"
$Properties = 'Caption', 'CSName', 'Version', 'BuildType', 'OSArchitecture'
Get-CimInstance Win32_OperatingSystem | Select-Object $Properties | Format-Table -AutoSize

# chocolatey functional tests fail so delete the chocolatey binary to avoid triggering them
Remove-Item -Path C:\ProgramData\chocolatey\bin\choco.exe -ErrorAction SilentlyContinue

echo "--- install ruby + devkit"
$ErrorActionPreference = 'Stop'

InstallRuby

# Set-Item -Path Env:Path -Value to include ruby26
$Env:Path+=";C:\ruby26\bin"

echo "--- configure winrm"

winrm quickconfig -q
ruby -v
bundle --version

echo "--- bundle install"
bundle install --jobs=3 --retry=3 --without omnibus_package docgen chefstyle

echo "+++ bundle exec rake spec:functional"
bundle exec rake spec:functional

exit $LASTEXITCODE
