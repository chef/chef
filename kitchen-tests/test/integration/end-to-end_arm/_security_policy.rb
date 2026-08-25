# Verifies recipes/_security_policy.rb: firewall profiles, defender exclusion, printers/ports.

describe powershell("(Get-NetFirewallProfile -Name Public).Enabled") do
  its(:stdout) { should match(/False/) }
end

describe powershell("(Get-NetFirewallProfile -Name Domain).Enabled") do
  its(:stdout) { should match(/True/) }
end

describe powershell("(Get-MpPreference).ExclusionExtension -contains 'png'") do
  its(:stdout) { should match(/True/) }
end

describe powershell("(Get-Printer -Name 'HP LaserJet 6th Floor').Name") do
  its(:stdout) { should match(/HP LaserJet 6th Floor/) }
end

describe powershell("(Get-Printer -Name 'HP LaserJet 5th Floor').Name") do
  its(:stdout) { should match(/HP LaserJet 5th Floor/) }
end

describe powershell("(Get-PrinterPort -Name 'My awesome port').PrinterHostAddress") do
  its(:stdout) { should match(/10\.4\.64\.39/) }
end

# Verifies the recipe caught the expected Win32 error itself rather than
# letting it abort the whole chef-client run.
describe file("C:\\chef_arm_test\\arm_test_user_cleanup_result.txt") do
  it { should exist }
  its("content") { should match(/caught/) }
end
