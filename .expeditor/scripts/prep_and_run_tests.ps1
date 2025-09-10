param(
    # The test type ot be run (unit, integration or functional)
    [Parameter(Position=0)][String]$TestType
)

# $env:Path = 'C:\Program Files\Git\mingw64\bin;C:\Program Files\Git\usr\bin;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Windows\System32\OpenSSH\;C:\ProgramData\chocolatey\bin;C:\Program Files (x86)\Windows Kits\8.1\Windows Performance Toolkit\;C:\Program Files\Git\cmd;C:\Users\ContainerAdministrator\AppData\Local\Microsoft\WindowsApps;' + $env:Path

if ($TestType -eq 'Functional') {
    winrm quickconfig -q
}

powershell -File "./.expeditor/scripts/ensure-minimum-viable-hab.ps1"
if (-not $?) { throw "Could not ensure the minimum hab version required is installed." }
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
$env:Path = "C:\hab\bin;" + $env:Path # add hab bin path for binlinking
$env:HAB_LICENSE = "accept-no-persist"

Write-Output "--- Checking the Chocolatey version"
$installed_version = Get-ItemProperty "${env:ChocolateyInstall}/choco.exe" | select-object -expandproperty versioninfo| select-object -expandproperty productversion
if(-not ($installed_version -match ('^2'))){
    Write-Output "--- Now Upgrading Choco"
    try {
        choco feature enable -n=allowGlobalConfirmation
        choco upgrade chocolatey
    }
    catch {
        Write-Output "Upgrade Failed"
        Write-Output $_
        <#Do this if a terminating exception happens#>
    }
}

Write-Output "--- Installing core/ruby3_4-plus-devkit via Habitat"
hab pkg install core/ruby3_4-plus-devkit --channel base-2025 --binlink --force
if (-not $?) { throw "Could not install ruby with devkit via Habitat." }
$ruby_dir = & hab pkg path core/ruby3_4-plus-devkit

Write-Output "--- Installing OpenSSL via Habitat"
hab pkg install core/openssl/3.5.0 --channel base-2025 --binlink --force
if (-not $?) { throw "Could not install OpenSSL via Habitat." }

# Set $openssl_dir to Habitat OpenSSL package installation path
$openssl_dir = & hab pkg path core/openssl/3.5.0
if (-not $openssl_dir) { throw "Could not determine core/openssl installation directory." }

hab pkg install core/cacerts --channel base-2025
$cacerts_dir = & hab pkg path core/cacerts
if (-not $cacerts_dir) { throw "Could not determine core/cacerts installation directory." }
# Set the env variables for OpenSSL
$env:SSL_CERT_FILE = "$cacerts_dir\ssl\certs\cacert.pem"
$env:RUBY_DLL_PATH = "$openssl_dir\bin"
$env:OPENSSL_CONF = "$openssl_dir\ssl\openssl.cnf"
$env:OPENSSL_ROOT_DIR = $openssl_dir
$env:OPENSSL_INCLUDE_DIR = "$openssl_dir\include"
$env:OPENSSL_LIB_DIR = "$openssl_dir\lib"

$env:Path = "$openssl_dir\bin;$ruby_dir\bin;" + $env:Path

Write-Output "Configure bundle to build openssl gem with $openssl_dir"
bundle config build.openssl --with-openssl-dir=$openssl_dir
gem install openssl:3.3.0 -- --with-openssl-dir=$openssl_dir --with-openssl-include="$openssl_dir\include" --with-openssl-lib="$openssl_dir\lib"

Write-Output "OpenSSL directory: $openssl_dir"
Write-Output "PATH: $env:Path"
Write-Output "SSL_CERT_FILE: $env:SSL_CERT_FILE"
Write-Output "RUBY_DLL_PATH: $env:RUBY_DLL_PATH"

Write-Output "--- Checking ruby, bundle, gem and openssl paths"
(Get-Command ruby).Source
(Get-Command bundle).Source
(Get-Command gem).Source
(Get-Command openssl).Source

Write-Output "--- Does ruby have openssl access?"
ruby -e "require 'openssl'; puts 'OpenSSL loaded successfully: ' + OpenSSL::OPENSSL_VERSION; puts 'OpenSSL gem version: ' + OpenSSL::VERSION;"

Write-Output "--- Running Chef bundle install"
bundle install --jobs=3 --retry=3

# making sure we find the dlls from chef powershell
$powershell_gem_lib = gem which chef-powershell | Select-Object -First 1
$powershell_gem_path = Split-Path $powershell_gem_lib | Split-Path
$env:RUBY_DLL_PATH = "$powershell_gem_path/bin/ruby_bin_folder/$env:PROCESSOR_ARCHITECTURE"

switch ($TestType) {
    "Unit"          {[string[]]$RakeTest = 'spec:unit','component_specs'; break}
    "Integration"   {[string[]]$RakeTest = "spec:integration"; break}
    "Functional"    {[string[]]$RakeTest = "spec:functional"; break}
    default         {throw "TestType $TestType not valid"}
}

function Get-ServiceLogs{
    # Script to analyze LanmanServer (Server) service events from System log
  Write-Host "Scanning System Event Log for LanmanServer Service Events..." -ForegroundColor Yellow
  Write-Host ("=" * 60) -ForegroundColor Yellow

  try {
      # Get events related to LanmanServer service from System log
      $ServerEvents = Get-WinEvent -FilterHashtable @{
          LogName = 'System'
          ProviderName = 'Service Control Manager'
      } -MaxEvents 1000 -ErrorAction Stop | Where-Object {
          $_.Message -like "*LanmanServer*" -or
          $_.Message -like "*Server*" -and $_.Message -like "*service*"
      }

      # Also check for any events with LanmanServer in the message from other providers
      $AdditionalEvents = Get-WinEvent -FilterHashtable @{
          LogName = 'System'
      } -MaxEvents 2000 -ErrorAction Stop | Where-Object {
          $_.Message -like "*LanmanServer*"
      }

      # Combine and sort events
      $AllEvents = @($ServerEvents) + @($AdditionalEvents) |
                  Sort-Object TimeCreated -Descending |
                  Select-Object -First 20

      if ($AllEvents.Count -eq 0) {
          Write-Host "No LanmanServer service events found in recent System log entries." -ForegroundColor Green

          # Check current service status
          Write-Host "`nCurrent Server Service Status:" -ForegroundColor Cyan
          Get-Service -Name "LanmanServer" | Format-Table Name, Status, StartType -AutoSize
      }
      else {
          Write-Host "Found $($AllEvents.Count) relevant events (showing most recent):" -ForegroundColor Green
          Write-Host ""

          foreach ($Event in $AllEvents) {
              # Color code based on event level
              $Color = switch ($Event.LevelDisplayName) {
                  "Error" { "Red" }
                  "Warning" { "Yellow" }
                  "Information" { "Green" }
                  default { "White" }
              }

              Write-Host "Time: $($Event.TimeCreated)" -ForegroundColor White
              Write-Host "Level: $($Event.LevelDisplayName)" -ForegroundColor $Color
              Write-Host "Event ID: $($Event.Id)" -ForegroundColor White
              Write-Host "Provider: $($Event.ProviderName)" -ForegroundColor White
              Write-Host "Message: $($Event.Message)" -ForegroundColor $Color
              Write-Host ("-" * 80) -ForegroundColor Gray
          }

          # Summary of event types
          Write-Host "`nEvent Summary:" -ForegroundColor Cyan
          $AllEvents | Group-Object LevelDisplayName |
              Select-Object Name, Count |
              Format-Table -AutoSize

          # Show most recent error if any
          $RecentError = $AllEvents | Where-Object { $_.LevelDisplayName -eq "Error" } | Select-Object -First 1
          if ($RecentError) {
              Write-Host "`nMost Recent Error Details:" -ForegroundColor Red
              Write-Host "Time: $($RecentError.TimeCreated)" -ForegroundColor White
              Write-Host "Event ID: $($RecentError.Id)" -ForegroundColor White
              Write-Host "Message: $($RecentError.Message)" -ForegroundColor Red
          }
      }

      # Additional diagnostic information
      Write-Host ("`n" + ("=" * 60)) -ForegroundColor Yellow
      Write-Host "Additional Diagnostic Information:" -ForegroundColor Yellow

      # Current service status
      Write-Host "`nServer Service Current Status:" -ForegroundColor Cyan
      $ServerService = Get-Service -Name "LanmanServer"
      Write-Host "Name: $($ServerService.Name)" -ForegroundColor White
      Write-Host "Display Name: $($ServerService.DisplayName)" -ForegroundColor White
      Write-Host "Status: $($ServerService.Status)" -ForegroundColor $(if($ServerService.Status -eq "Running"){"Green"}else{"Red"})
      Write-Host "Start Type: $($ServerService.StartType)" -ForegroundColor White

      # Check for dependent services
      Write-Host "`nDependent Services:" -ForegroundColor Cyan
      $DependentServices = Get-Service -Name "LanmanServer" | Select-Object -ExpandProperty DependentServices
      if ($DependentServices) {
          $DependentServices | Format-Table Name, Status, StartType -AutoSize
      } else {
          Write-Host "No dependent services found." -ForegroundColor White
      }

      # Check services that LanmanServer depends on
      Write-Host "Services that LanmanServer depends on:" -ForegroundColor Cyan
      $ServiceDependencies = Get-Service -Name "LanmanServer" | Select-Object -ExpandProperty ServicesDependedOn
      if ($ServiceDependencies) {
          $ServiceDependencies | Format-Table Name, Status, StartType -AutoSize
      } else {
          Write-Host "No service dependencies found." -ForegroundColor White
      }

  }
  catch {
      Write-Host "Error accessing System Event Log: $($_.Exception.Message)" -ForegroundColor Red
      Write-Host "You may need to run this script as Administrator." -ForegroundColor Yellow
  }

}

if ( $RakeTest -match 'functional' ) {
  # Check and manage LanmanServer service
  try {
      Write-Host "Checking LanmanServer service status..." -ForegroundColor Yellow

      # Get the service object
      $service = Get-Service -Name "LanmanServer" -ErrorAction Stop
      $serviceWMI = Get-WmiObject -Class Win32_Service -Filter "Name='LanmanServer'" -ErrorAction Stop

      Write-Host "Current service status: $($service.Status)" -ForegroundColor Cyan
      Write-Host "Current startup type: $($serviceWMI.StartMode)" -ForegroundColor Cyan

      Write-Host "Getting current Service logs for diagnostics..." -ForegroundColor Yellow
      Get-ServiceLogs

      # Check if service is disabled and enable it
      if ($serviceWMI.StartMode -eq "Disabled") {
          Write-Host "Service is disabled. Attempting to enable..." -ForegroundColor Yellow
          $result = Set-Service -Name "LanmanServer" -StartupType Automatic -ErrorAction Stop
          Write-Host "Service has been enabled (Automatic startup)" -ForegroundColor Green
      }

      # Check if service is stopped and start it
      if ($service.Status -ne "Running") {
          Write-Host "Service is not running. Attempting to start..." -ForegroundColor Yellow
          Start-Service -Name "LanmanServer" -ErrorAction Stop

          # Wait for service to start and verify
          $timeout = 30 # seconds
          $timer = 0
          do {
              Start-Sleep -Seconds 1
              $timer++
              $service = Get-Service -Name "LanmanServer"
          } while ($service.Status -ne "Running" -and $timer -lt $timeout)

          if ($service.Status -eq "Running") {
              Write-Host "LanmanServer service started successfully!" -ForegroundColor Green
          } else {
              throw "Service failed to start within $timeout seconds. Current status: $($service.Status)"
          }
      } else {
          Write-Host "LanmanServer service is already running!" -ForegroundColor Green
      }
  }
  catch {
      Write-Error "CRITICAL FAILURE: Unable to manage LanmanServer service. Error: $($_.Exception.Message)" -ErrorAction Stop
      exit 1
  }

  Write-Host "LanmanServer service is now running and properly configured." -ForegroundColor Green
}

foreach($test in $RakeTest) {
    Write-Output "--- Chef $test run"
    bundle exec rake $test
    if (-not $?) { throw "Chef $test tests failed" }
}
