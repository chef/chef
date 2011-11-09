def debian_compatible?
  (ohai[:platform] == 'debian') || (ohai[:platform] == "ubuntu")
end

def chef_test_dpkg_installed?
  shell_out("dpkg -l chef-integration-test").status.success?
end

def purge_chef_integration_debs
  if debian_compatible? && chef_test_dpkg_installed?
    shell_out!("dpkg -r chef-integration-test")
    shell_out("dpkg --clear-avail")
  end
end

Given /^I have configured my apt sources for integration tests$/ do
  File.open("/etc/apt/sources.list.d/chef-integration-test.list", "w+") do |f|
    f.puts "deb http://localhost:9000/ sid main"
  end
end

def remove_integration_test_apt_source
  FileUtils.rm("/etc/apt/sources.list.d/chef-integration-test.list")
rescue Errno::ENOENT
  Chef::Log.info("Attempted to remove integration test from /etc/apt/sources.list.d but it didn't exist")
end

After("@apt") do
  remove_integration_test_apt_source
  purge_chef_integration_debs
  shell_out! "apt-get clean" if debian_compatible?
end

Before('@dpkg') do
  purge_chef_integration_debs if debian_compatible?
end

Before('@apt') do
  purge_chef_integration_debs
  shell_out!("apt-get clean") if debian_compatible?
end

After('@dpkg') do
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
  source = File.expand_path(File.dirname(__FILE__) + "/../data/apt/#{pkg_name}-1_amd64.deb")
  dest = File.join(tmpdir, File.basename(source))
  FileUtils.cp(source, dest)
end

Given "the apt server is running" do
  self.apt_server_thread = Thread.new do
    trap("INT") do
      apt_server.shutdown
      apt_server_thread.join
    end

    apt_server.start
  end

  Chef::Log.debug "Waiting for apt server to start"
  until tcp_test_port("localhost", 9000) do
    Chef::Log.debug "."
    sleep 1
  end
  Chef::Log.debug "done"
end

Given "I have updated my apt cache" do
  shell_out!("apt-get update")
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

def dpkg_should_be_installed(pkg_name)
  shell_out!("dpkg -l #{pkg_name}")
end

Then "the dpkg package '$package_name' should be installed" do |package_name|
  dpkg_should_be_installed(package_name)
end

def tcp_test_port(hostname, port)
  tcp_socket = TCPSocket.new(hostname, port)
  true
rescue Errno::ETIMEDOUT
  false
rescue Errno::ECONNREFUSED
  false
ensure
  tcp_socket && tcp_socket.close
end
