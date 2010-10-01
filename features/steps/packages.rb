def debian_compatible?
  (ohai[:platform] == 'debian') || (ohai[:platform] == "ubuntu")
end

def chef_test_dpkg_installed?
  shell_out("dpkg -l chef-integration-test").exitstatus.success?
end

def purge_chef_integration_debs
  if debian_compatible? && chef_test_dpkg_installed?
    shell_out!("dpkg -r chef-integration-test")
  end
end

Before('@dpkg', '@apt') do
  purge_chef_integration_debs
end

AfterStep('@dpkg', '@apt') do
  purge_chef_integration_debs
end

Given "I am running on a debian compatible OS" do
  unless debian_compatible?
    pending("This test can only run on debian or ubuntu, but you have #{ohai[:platform]}")
  end
end

Given "my dpkg architecture is 'amd64'" do
  unless `dpkg --print-architecture`.strip == "amd64"
    pending("This scenario can only run on an amd64 system")
  end
end

Given "the deb package '$pkg_name' is available" do |pkg_name|
  source = File.expand_path(File.dirname(__FILE__) + "/data/apt/#{pkg_name}-1_amd64.deb")
  dest = File.join(tmpdir, File.basename(source))
  FileUtils.cp(source, dest)
end

Given /^the gems server is running$/ do
  self.gemserver_thread = Thread.new do
    trap("INT") do 
      gemserver.shutdown
      gemserver_thread.join
    end
    
    gemserver.start
  end
end

Given /^that I have the (.+) package system installed$/ do |package_system|
  unless package_system_available?(package_system)
    pending "This Cucumber feature will not execute, as it is missing the #{package_system} packaging system."
  end
end

Then /^there should be a binary on the path called '(.+)'$/ do |binary_name|
  binary_name.strip!
  result = `which #{binary_name}`
  result.should_not =~ /not found/
end

Then /^there should not be a binary on the path called '(.+)'$/ do |binary_name|
  binary_name.strip!
  result = `which #{binary_name}`.strip

  unless result.empty?
    result.should =~ /not found/
  end
end

Then /^the gem '(.+)' version '(.+)' should be installed$/ do |gem_name, version|
  Then "a file named 'installed-gems/gems/#{gem_name}-#{version}' should exist"
end

Then "the gem '$gem_name' version '$version' should not be installed" do |gem_name, version|
  Then "a file named 'installed-gems/gems/#{gem_name}-#{version}' should not exist"
end

Then "the dpkg package '$package_name' should be installed" do |package_name|
  pending # express the regexp above with the code you wish you had
end

