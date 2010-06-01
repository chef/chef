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