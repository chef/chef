# Chef PowerShell Validation Script
# This script replicates the kitchen.exec.windows.yml installation steps
# and validates Chef's PowerShell integration in a Windows environment

param(
    [string]$GitHubSHA = $env:GITHUB_SHA,
    [string]$GitHubRepository = $env:GITHUB_REPOSITORY
)

# Set error action preference
$ErrorActionPreference = 'Stop'

# Disable any automatic encoding changes that might cause issues in containers
$env:POWERSHELL_TELEMETRY_OPTOUT = 1

# Add some environment debugging
Write-Output "==> Environment Information:"
Write-Output "PowerShell Version: $($PSVersionTable.PSVersion)"
Write-Output "OS Version: $([Environment]::OSVersion.VersionString)"
Write-Output "Working Directory: $(Get-Location)"

try {
    Write-Output "==> Installing Chef..."
    
    # Download and execute the Chef installer
    # Note: The installer tries to set OutputEncoding which fails in containers
    # We'll work around this by pre-emptively handling the error
    try {
        # Download the installer script first
        Write-Output "Downloading Chef installer..."
        $installerScript = Invoke-WebRequest -Uri https://omnitruck.chef.io/install.ps1 -UseBasicParsing
        Write-Output "[ok] Downloaded installer script"
        
        # Execute the installer script content
        # We need to handle the OutputEncoding issue that occurs in containers
        Write-Output "Executing installer..."
        $scriptContent = $installerScript.Content
        
        # Create a modified version that doesn't set OutputEncoding
        # The installer tries to set [Console]::OutputEncoding which fails in containers
        $scriptContent = $scriptContent -replace '\[Console\]::OutputEncoding\s*=.*', '# OutputEncoding setting removed for container compatibility'
        
        # Execute the modified script
        Invoke-Expression $scriptContent
        Write-Output "[ok] Installer functions loaded"
        
        # Now call Install-Project
        Write-Output "Installing Chef..."
        Install-Project -project chef -channel current
        Write-Output "[ok] Chef installation completed"
    } catch {
        Write-Error "[fail] Chef installation failed: $_"
        throw
    }
    
    # Set PATH
    Write-Output "==> Setting PATH environment..."
    $originalPath = $env:PATH
    $env:PATH = "C:\opscode\chef\bin;C:\opscode\chef\embedded\bin;" + $env:PATH
    Write-Output "[ok] PATH updated"
    
    # Verify initial installation
    Write-Output "==> Verifying Chef installation..."
    try {
        $chefVersion = chef-client -v 2>&1
        if ($LASTEXITCODE -ne 0) { throw "chef-client version check failed with exit code $LASTEXITCODE" }
        Write-Output "[ok] Chef client: $chefVersion"
    } catch {
        Write-Error "[fail] Chef client verification failed: $_"
        throw
    }
    
    try {
        $ohaiVersion = ohai -v 2>&1
        if ($LASTEXITCODE -ne 0) { throw "ohai version check failed with exit code $LASTEXITCODE" }
        Write-Output "[ok] Ohai: $ohaiVersion"
    } catch {
        Write-Error "[fail] Ohai verification failed: $_"
        throw
    }
    
    try {
        $rakeVersion = rake --version 2>&1
        if ($LASTEXITCODE -ne 0) { throw "rake version check failed with exit code $LASTEXITCODE" }
        Write-Output "[ok] Rake: $rakeVersion"
    } catch {
        Write-Error "[fail] Rake verification failed: $_"
        throw
    }
    
    try {
        $bundleVersion = bundle -v 2>&1
        if ($LASTEXITCODE -ne 0) { throw "bundle version check failed with exit code $LASTEXITCODE" }
        Write-Output "[ok] Bundle: $bundleVersion"
    } catch {
        Write-Error "[fail] Bundle verification failed: $_"
        throw
    }
    
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
    $recipe_lines | Set-Content -Path 'validate_powershell.rb'
    
    # Run the PowerShell recipe with Chef
    Write-Output "==> Running PowerShell validation recipe..."
    chef-client --local-mode --runlist "recipe[validate_powershell]" --file-cache-path C:\temp\chef-cache --cookbook-path . --log-level info
    
    if ($LASTEXITCODE -eq 0) {
        Write-Output "[ok] PowerShell recipe executed successfully!"
        
        # Verify the test file was created
        if (Test-Path "C:\temp\chef_test.txt") {
            $content = Get-Content "C:\temp\chef_test.txt"
            Write-Output "[ok] Test file content: $content"
        } else {
            Write-Warning "[attention]  Test file was not found"
        }
        
        Write-Output "[ok] Chef PowerShell validation completed successfully!"
        exit 0
    } else {
        throw "PowerShell recipe execution failed"
    }
    
} catch {
    Write-Error "[fail] Validation failed: $_"
    exit 1
}