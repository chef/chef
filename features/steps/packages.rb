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
