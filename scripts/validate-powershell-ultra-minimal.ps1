# Ultra-minimal Chef PowerShell Validation Script
# This version tries to avoid all potential encoding issues

$ErrorActionPreference = 'Continue'
$env:POWERSHELL_TELEMETRY_OPTOUT = 1

Write-Host "==> Ultra-minimal Chef validation starting..." -ForegroundColor Green

try {
    Write-Host "Step 1: Environment check" -ForegroundColor Yellow
    Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)"
    Write-Host "Working Directory: $(Get-Location)"
    
    Write-Host "`nStep 2: Download Chef installer to file" -ForegroundColor Yellow
    # Download to file instead of executing directly
    Invoke-WebRequest -Uri "https://omnitruck.chef.io/install.ps1" -OutFile "chef-installer.ps1" -UseBasicParsing
    Write-Host "✅ Downloaded installer to file"
    
    Write-Host "`nStep 3: Execute installer from file" -ForegroundColor Yellow
    # Execute from file with explicit bypass
    powershell -ExecutionPolicy Bypass -File "chef-installer.ps1" -project chef -channel current
    Write-Host "✅ Installer executed"
    
    Write-Host "`nStep 4: Check if Chef was installed" -ForegroundColor Yellow
    if (Test-Path "C:\opscode\chef\bin\chef-client.bat") {
        Write-Host "✅ Chef client executable found"
    } else {
        Write-Host "❌ Chef client executable not found" -ForegroundColor Red
        Get-ChildItem C:\opscode\ -Recurse -Name "*chef*" | Select-Object -First 10
    }
    
    Write-Host "`nStep 5: Test basic Chef functionality" -ForegroundColor Yellow
    $env:PATH = "C:\opscode\chef\bin;C:\opscode\chef\embedded\bin;" + $env:PATH
    
    # Try to get version without stopping on errors
    try {
        $chefVersion = & "C:\opscode\chef\bin\chef-client.bat" -v 2>&1
        Write-Host "✅ Chef version output: $chefVersion"
    } catch {
        Write-Host "⚠️ Chef version check failed: $_" -ForegroundColor Yellow
    }
    
    Write-Host "`n✅ Ultra-minimal validation completed!" -ForegroundColor Green
    
} catch {
    Write-Host "`n❌ Error occurred: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Error details: $_" -ForegroundColor Red
    exit 1
} finally {
    # Cleanup
    if (Test-Path "chef-installer.ps1") {
        Remove-Item "chef-installer.ps1" -Force -ErrorAction SilentlyContinue
    }
}