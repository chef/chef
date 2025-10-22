# Git Installation for Windows Server Core Containers

## Problem

The `appbundle-updater` tool requires git to fetch the Chef repository and build from a specific SHA. Windows Server Core containers don't include git by default.

## Solution

Install MinGit (a minimal Git distribution for Windows) before running `appbundle-updater`.

### Implementation

```powershell
# Install git (required by appbundle-updater)
Write-Output "==> Installing Git..."
try {
    # Download Git for Windows minimal installer
    $gitVersion = "2.47.0"
    $gitInstallerUrl = "https://github.com/git-for-windows/git/releases/download/v$gitVersion.windows.1/MinGit-$gitVersion-64-bit.zip"
    $gitZip = "C:\temp\mingit.zip"
    $gitPath = "C:\git"
    
    # Create temp directory
    New-Item -Path "C:\temp" -ItemType Directory -Force | Out-Null
    
    # Download MinGit
    Write-Output "Downloading Git from $gitInstallerUrl..."
    Invoke-WebRequest -Uri $gitInstallerUrl -OutFile $gitZip -UseBasicParsing
    
    # Extract Git
    Write-Output "Extracting Git to $gitPath..."
    Expand-Archive -Path $gitZip -DestinationPath $gitPath -Force
    
    # Add Git to PATH
    $env:PATH = "$gitPath\cmd;$gitPath\mingw64\bin;" + $env:PATH
    
    # Verify Git is available
    $gitVersionOutput = git --version 2>&1
    Write-Output "[OK] Git installed: $gitVersionOutput"
    
    # Clean up
    Remove-Item $gitZip -Force -ErrorAction SilentlyContinue
} catch {
    Write-Warning "Git installation failed: $_"
    Write-Output "Continuing without git - will need GITHUB_SHA environment variable"
}
```

## Why MinGit?

MinGit is a portable, minimal version of Git for Windows that:
- Is ~50MB (vs ~250MB for full Git for Windows)
- Doesn't require administrator privileges
- Doesn't require an interactive installer
- Contains only the essential git commands
- Perfect for CI/CD environments

## Fallback Strategy

If git installation fails or is not available, the script will fall back to using the `GITHUB_SHA` environment variable:

```powershell
# Determine GitHub SHA
if ($GitHubSHA) {
    $github_sha = $GitHubSHA
    Write-Output "Using provided GitHub SHA: $github_sha"
} else {
    # Try to get SHA from git
    try {
        $gitCommand = Get-Command git -ErrorAction SilentlyContinue
        if ($gitCommand) {
            $github_sha = (git rev-parse HEAD 2>&1)
            if ($LASTEXITCODE -eq 0) {
                $github_sha = $github_sha.Trim()
                Write-Output "Using SHA from git: $github_sha"
            } else {
                throw "git rev-parse failed"
            }
        } else {
            throw "git command not found"
        }
    } catch {
        Write-Error "Cannot determine GitHub SHA: git is not available and GITHUB_SHA environment variable is not set"
        throw "GitHub SHA is required for appbundle-updater"
    }
}
```

## GitHub Actions Integration

The workflow passes the SHA via environment variable:

```yaml
docker run --rm \
  -v "${PWD}:C:\workspace" \
  -w C:\workspace \
  -e "GITHUB_SHA=${{ github.sha }}" \
  -e "GITHUB_REPOSITORY=${{ github.repository }}" \
  mcr.microsoft.com/windows/servercore:ltsc2022 \
  powershell -ExecutionPolicy Bypass -File "scripts\validate-powershell.ps1"
```

## Testing

To test the git installation:

```powershell
# Test in container
docker run --rm -v "${PWD}:C:\workspace" -w C:\workspace mcr.microsoft.com/windows/servercore:ltsc2022 powershell -ExecutionPolicy Bypass -Command "
  & C:\workspace\scripts\validate-powershell.ps1
"
```

## Alternative: Use Environment Variable Only

If you don't want to install git in the container, you can skip the appbundle-updater step and rely on the already-installed Chef version, or always pass the GITHUB_SHA environment variable.

## Size Considerations

- MinGit download: ~50MB
- Extracted size: ~130MB
- Download time in CI: ~10-20 seconds depending on network

This is acceptable overhead for proper Chef validation functionality.
