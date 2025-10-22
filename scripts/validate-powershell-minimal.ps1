# Minimal Chef PowerShell Validation Script for debugging
# This is a simplified version to identify the exact failure point

$ErrorActionPreference = 'Continue'  # Use Continue instead of Stop for better debugging

Write-Host "==> Starting minimal validation..." -ForegroundColor Green

try {
    Write-Host "Step 1: Environment check" -ForegroundColor Yellow
    Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)"
    Write-Host "OS Version: $([Environment]::OSVersion.VersionString)"
    Write-Host "Working Directory: $(Get-Location)"
    Write-Host "Current PATH: $($env:PATH)"
    
    Write-Host "`nStep 2: Testing Chef installer download" -ForegroundColor Yellow
    $installScript = Invoke-WebRequest -Uri https://omnitruck.chef.io/install.ps1 -UseBasicParsing
    Write-Host "[ok] Downloaded installer script ($($installScript.Content.Length) bytes)"
    
    Write-Host "`nStep 3: Executing installer (with container compatibility fix)" -ForegroundColor Yellow
    # Remove OutputEncoding setting that fails in containers
    $scriptContent = $installScript.Content -replace '\[Console\]::OutputEncoding\s*=.*', '# OutputEncoding setting removed for container compatibility'
    Invoke-Expression $scriptContent
    Write-Host "[ok] Installer functions loaded"
    
    Write-Host "`nStep 4: Installing Chef" -ForegroundColor Yellow
    Install-Project -project chef -channel current
    Write-Host "[ok] Chef installation completed"
    
    Write-Host "`nStep 5: Updating PATH" -ForegroundColor Yellow
    $env:PATH = "C:\opscode\chef\bin;C:\opscode\chef\embedded\bin;" + $env:PATH
    Write-Host "[ok] PATH updated"
    Write-Host "New PATH: $($env:PATH)"
    
    Write-Host "`nStep 6: Testing chef-client" -ForegroundColor Yellow
    $chefOutput = chef-client -v
    Write-Host "[ok] Chef version: $chefOutput"
    
    Write-Host "`nStep 7: Testing ohai" -ForegroundColor Yellow
    $ohaiOutput = ohai -v
    Write-Host "[ok] Ohai version: $ohaiOutput"
    
    Write-Host "`n[ok] Minimal validation completed successfully!" -ForegroundColor Green
    
} catch {
    Write-Host "`n[fail] Error occurred: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Error details: $_" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}