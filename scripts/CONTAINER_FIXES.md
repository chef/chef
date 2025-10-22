# PowerShell Container Compatibility Fixes

## Issue Summary

When running Chef installation scripts in Windows Server Core Docker containers, two main issues occur:

### 1. UseBasicParsing Parameter Duplication
**Error**: `Cannot bind parameter because parameter 'UseBasicParsing' is specified more than once`

**Cause**: The `-useb` parameter is shorthand for `-UseBasicParsing`. Using both causes duplication.

**Fix**: Use explicit `-UseBasicParsing` instead of `-useb`:
```powershell
# ❌ Wrong
Invoke-WebRequest -useb https://omnitruck.chef.io/install.ps1 -UseBasicParsing

# ✅ Correct
Invoke-WebRequest -Uri https://omnitruck.chef.io/install.ps1 -UseBasicParsing
```

### 2. OutputEncoding Not Supported in Containers
**Error**: `Exception setting "OutputEncoding": "The request is not supported."`

**Cause**: The Chef omnitruck installer script tries to set `[Console]::OutputEncoding`, which is not supported in Windows Server Core containers that don't have a console allocated.

**Fix**: Download the installer script, remove the OutputEncoding line, then execute:
```powershell
# Download the installer
$installerScript = Invoke-WebRequest -Uri https://omnitruck.chef.io/install.ps1 -UseBasicParsing

# Remove the problematic OutputEncoding setting
$scriptContent = $installerScript.Content -replace '\[Console\]::OutputEncoding\s*=.*', '# OutputEncoding setting removed for container compatibility'

# Execute the modified script
Invoke-Expression $scriptContent

# Now the Install-Project function is available
Install-Project -project chef -channel current
```

## Files Modified

- `scripts/validate-powershell.ps1` - Main validation script with container fixes
- `scripts/validate-powershell-minimal.ps1` - Minimal test script for debugging
- `.github/workflows/validate-powershell.yml` - GitHub Actions workflow

## Testing

Run the minimal script first to verify the fix:
```powershell
docker run --rm -v "${PWD}:C:\workspace" -w C:\workspace mcr.microsoft.com/windows/servercore:ltsc2022 powershell -ExecutionPolicy Bypass -File "scripts\validate-powershell-minimal.ps1"
```

Then run the full validation:
```powershell
docker run --rm -v "${PWD}:C:\workspace" -w C:\workspace mcr.microsoft.com/windows/servercore:ltsc2022 powershell -ExecutionPolicy Bypass -File "scripts\validate-powershell.ps1"
```

## Technical Details

### Why OutputEncoding Fails in Containers

Windows Server Core containers run in a minimal environment without a full console subsystem. When the Chef installer tries to set `[Console]::OutputEncoding`, it fails because:

1. The console object doesn't fully support property modification in container environments
2. The container may not have the necessary encoding infrastructure initialized
3. Server Core images are stripped down and don't include all console features

### Alternative Solutions Considered

1. **Pre-set OutputEncoding** - Doesn't work, same error occurs
2. **Redirect to $null** - Loses valuable debug output
3. **Use different installer** - Would require maintaining custom installer
4. **Modify environment** - Container changes would affect all scripts

The chosen solution (regex replacement) is the least invasive and most maintainable approach.
