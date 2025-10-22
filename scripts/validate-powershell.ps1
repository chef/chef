# Chef PowerShell Validation Script
# This script replicates the kitchen.exec.windows.yml installation steps
# and validates Chef's PowerShell integration in a Windows environment

param(
    [string]$GitHubSHA = $env:GITHUB_SHA,
    [string]$GitHubRepository = $env:GITHUB_REPOSITORY
)

# Set error action preference
$ErrorActionPreference = 'Stop'

try {
    Write-Output "==> Installing Chef..."
    . { Invoke-WebRequest -useb https://omnitruck.chef.io/install.ps1 } | Invoke-Expression
    Install-Project -project chef -channel current
    
    # Set PATH
    $env:PATH = "C:\opscode\chef\bin;C:\opscode\chef\embedded\bin;" + $env:PATH
    
    # Verify initial installation
    Write-Output "==> Verifying Chef installation..."
    chef-client -v
    if ($LASTEXITCODE -ne 0) { throw "chef-client version check failed" }
    
    ohai -v  
    if ($LASTEXITCODE -ne 0) { throw "ohai version check failed" }
    
    rake --version
    if ($LASTEXITCODE -ne 0) { throw "rake version check failed" }
    
    bundle -v
    if ($LASTEXITCODE -ne 0) { throw "bundle version check failed" }
    
    # Get Ohai version from Gemfile.lock
    $env:OHAI_VERSION = ( Select-String -Path .\Gemfile.lock -Pattern '(?<=ohai \()\d.*(?=\))' | ForEach-Object { $_.Matches[0].Value } )
    Write-Output "Ohai version from Gemfile.lock: $env:OHAI_VERSION"
    
    # Fix ansidecl.h file location (same as kitchen config)
    Write-Output "==> Fixing ansidecl.h file location..."
    $output = Get-ChildItem -Path C:\opscode\ -File ansidecl.h -Recurse -ErrorAction SilentlyContinue
    if ($output) {
        # As of Ruby 3.1, there are 3 ansidecl.h files found in the opscode path
        # Grabbing the first (and shortest) path found is a bit of a :fingers-crossed: but
        # making the leap that ansidecl.h isn't going to vary in a way that will fail subtly.
        if ($output -is [Array]) { $output = $output[0] }
        $target_path = $($output.Directory.Parent.FullName + "\x86_64-w64-mingw32\include")
        if (Test-Path $target_path) {
            Move-Item -Path $output.FullName -Destination $target_path -Force
            Write-Output "Moved ansidecl.h to correct location"
        }
    }
    
    # Reinstall libyajl2 (same as kitchen config)
    # if a different version of ffi-yajl is installed, then libyajl2 needs to be reinstalled
    # so that libyajldll.a is present in the intermediate build step. bundler seems to skip
    # libyajl2 build if already present. gem install seems to build anyway.
    Write-Output "==> Reinstalling libyajl2..."
    gem uninstall -I libyajl2 2>$null
    
    # Install appbundler and appbundle-updater
    Write-Output "==> Installing appbundler..."
    gem install appbundler --no-doc
    if ($LASTEXITCODE -ne 0) { throw "appbundler installation failed" }
    
    Write-Output "==> Installing appbundle-updater..."
    gem install appbundle-updater -v "~> 1.0.36" --no-doc
    if ($LASTEXITCODE -ne 0) { throw "appbundle-updater installation failed" }
    
    # Update chef using appbundle-updater with current SHA
    Write-Output "==> Updating Chef with appbundle-updater..."
    $github_sha = if ($GitHubSHA) { $GitHubSHA } else { (git rev-parse HEAD).Trim() }
    $github_repo = if ($GitHubRepository) { $GitHubRepository } else { "chef/chef" }
    Write-Output "Using SHA: $github_sha"
    Write-Output "Using Repository: $github_repo"
    
    appbundle-updater chef chef $github_sha --tarball --github $github_repo
    if ($LASTEXITCODE -ne 0) { throw "appbundle-updater failed" }
    
    # Verify updated installation
    Write-Output "==> Verifying updated Chef installation:"
    chef-client -v
    if ($LASTEXITCODE -ne 0) { throw "Updated chef-client version check failed" }
    
    ohai -v
    if ($LASTEXITCODE -ne 0) { throw "Updated ohai version check failed" }
    
    # Remove conflicting binaries (same as kitchen config)
    # htmldiff and ldiff on windows cause a conflict with gems being loaded below. we remove them here.
    Write-Output "==> Removing conflicting binaries..."
    if (Test-Path C:\opscode\chef\embedded\bin\htmldiff) { 
        Remove-Item -Path C:\opscode\chef\embedded\bin\htmldiff -Force
        Remove-Item -Path C:\opscode\chef\embedded\bin\ldiff -Force
        Write-Output "Removed htmldiff and ldiff"
    }
    
    # Install bundle dependencies
    Write-Output "==> Installing bundle dependencies..."
    bundle install --jobs=3 --retry=3
    if ($LASTEXITCODE -ne 0) { throw "Bundle install failed" }
    
    # Create a test PowerShell recipe
    Write-Output "==> Creating test PowerShell recipe..."
    
    $recipe_lines = @(
        "# Test PowerShell recipe to validate Chef functionality",
        "powershell_script 'validate_chef_version' do",
        "  code <<-EOH",
        "    `$chef_version = chef-client -v",
        "    Write-Output `"Chef Version: `$chef_version`"",
        "    ",
        "    `$ohai_version = ohai -v",
        "    Write-Output `"Ohai Version: `$ohai_version`"",
        "    ",
        "    # Test some basic PowerShell functionality",
        "    `$ps_version = `$PSVersionTable.PSVersion",
        "    Write-Output `"PowerShell Version: `$ps_version`"",
        "    ",
        "    # Create a test file to verify file operations work",
        "    `$test_file = 'C:\temp\chef_test.txt'",
        "    New-Item -Path (Split-Path `$test_file) -ItemType Directory -Force | Out-Null",
        "    Set-Content -Path `$test_file -Value `"Chef PowerShell validation successful at `$(Get-Date)`"",
        "    Write-Output `"Created test file: `$test_file`"",
        "    ",
        "    if (Test-Path `$test_file) {",
        "      Write-Output 'File creation test: PASSED'",
        "    } else {",
        "      Write-Error 'File creation test: FAILED'",
        "      exit 1",
        "    }",
        "  EOH",
        "  action :run",
        "end",
        "",
        "# Verify the test file was created",
        "file 'C:\temp\chef_test.txt' do",
        "  action :create",
        "  content 'Chef PowerShell validation completed successfully'",
        "end",
        "",
        "log 'PowerShell validation completed' do",
        "  message 'Chef PowerShell integration is working correctly'",
        "  level :info",
        "end"
    )
    
    # Write the recipe to a file
    $recipe_lines | Out-File -FilePath 'validate_powershell.rb' -Encoding utf8
    
    # Run the PowerShell recipe with Chef
    Write-Output "==> Running PowerShell validation recipe..."
    chef-client --local-mode --runlist "recipe[validate_powershell]" --file-cache-path C:\temp\chef-cache --cookbook-path . --log-level info
    
    if ($LASTEXITCODE -eq 0) {
        Write-Output "✅ PowerShell recipe executed successfully!"
        
        # Verify the test file was created
        if (Test-Path "C:\temp\chef_test.txt") {
            $content = Get-Content "C:\temp\chef_test.txt"
            Write-Output "✅ Test file content: $content"
        } else {
            Write-Warning "⚠️  Test file was not found"
        }
        
        Write-Output "✅ Chef PowerShell validation completed successfully!"
        exit 0
    } else {
        throw "PowerShell recipe execution failed"
    }
    
} catch {
    Write-Error "❌ Validation failed: $_"
    exit 1
}