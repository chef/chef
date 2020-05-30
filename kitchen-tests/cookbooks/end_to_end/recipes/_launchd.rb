#
# Cookbook:: end_to_end
# Recipe:: launchd
#

file "/Library/LaunchDaemons/io.chef.testing.fake.plist" do
  path "io.chef.testing.fake.plist"
  mode "644"
end

launchd "io.chef.testing.fake" do
  source "io.chef.testing.fake"
end
