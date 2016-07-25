only_if do
  os["family"] == "windows"
end

describe command("chef-service-manager") do
  it { should exist }
  its("exit_status") { should eq 0 }
end

describe service("chef-client") do
  it { should_not be_enabled }
  it { should_not be_installed }
  it { should_not be_running }
end

describe command("/opscode/chef/bin/chef-service-manager.bat -a install") do
  its("exit_status") { should eq 0 }
  its(:stdout) { should match /Service 'chef-client' has successfully been installed./ }
end

describe service("chef-client") do
  it { should be_enabled }
  it { should be_installed }
  it { should_not be_running }
end

describe command("/opscode/chef/bin/chef-service-manager.bat -a start") do
  its("exit_status") { should eq 0 }
  its(:stdout) { should match /Service 'chef-client' is now 'running'/ }
end

describe service("chef-client") do
  it { should be_enabled }
  it { should be_installed }
  it { should be_running }
end

describe command("/opscode/chef/bin/chef-service-manager.bat -a stop") do
  its("exit_status") { should eq 0 }
  its(:stdout) { should match /Service 'chef-client' is now 'stopped'/ }
end

describe service("chef-client") do
  it { should be_enabled }
  it { should be_installed }
  it { should_not be_running }
end

describe command("/opscode/chef/bin/chef-service-manager.bat -a uninstall") do
  its("exit_status") { should eq 0 }
  its(:stdout) { should match /Service chef-client deleted/ }
end

describe service("chef-client") do
  it { should_not be_enabled }
  it { should_not be_installed }
  it { should_not be_running }
end
