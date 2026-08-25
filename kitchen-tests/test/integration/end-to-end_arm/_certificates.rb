# Verifies recipes/_certificates.rb: the generated cert files exist and were
# installed into the expected certificate stores.
cert_dir = "C:\\chef_arm_test\\certs"

describe file("#{cert_dir}\\chef-arm-test.pfx") do
  it { should exist }
end

describe file("#{cert_dir}\\chef-arm-test.cer") do
  it { should exist }
end

describe powershell("(Get-ChildItem Cert:\\CurrentUser\\My | Where-Object { $_.Subject -match 'chef-arm-test.local' }).Subject") do
  its(:stdout) { should match(/chef-arm-test.local/) }
end

describe powershell("(Get-ChildItem Cert:\\LocalMachine\\Root | Where-Object { $_.Subject -match 'chef-arm-test.local' }).Subject") do
  its(:stdout) { should match(/chef-arm-test.local/) }
end
