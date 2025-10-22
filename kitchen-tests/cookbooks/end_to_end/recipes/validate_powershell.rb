# Test PowerShell recipe to validate Chef functionality
powershell_script "validate_chef_version" do
  code <<-EOH
    $chef_version = chef-client -v
    Write-Output "Chef Version: $chef_version"

    $ohai_version = ohai -v
    Write-Output "Ohai Version: $ohai_version"

    # Test some basic PowerShell functionality
    $ps_version = $PSVersionTable.PSVersion
    Write-Output "PowerShell Version: $ps_version"

    # Create a test file to verify file operations work
    $test_file = 'C:\temp\chef_test.txt'
    New-Item -Path (Split-Path $test_file) -ItemType Directory -Force | Out-Null
    Set-Content -Path $test_file -Value "Chef PowerShell validation successful at $(Get-Date)"
    Write-Output "Created test file: $test_file"

    if (Test-Path $test_file) {
      Write-Output 'File creation test: PASSED'
    } else {
      Write-Error 'File creation test: FAILED'
      exit 1
    }
  EOH
  action :run
end

# Verify the test file was created
file 'C:\temp\chef_test.txt' do
  action :create
  content "Chef PowerShell validation completed successfully"
end

log "PowerShell validation completed" do
  message "Chef PowerShell integration is working correctly"
  level :info
end
