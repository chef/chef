dpkg_package("chef-integration-test") do
  source("#{File.join(node[:tmpdir], 'chef-integration-test_1.0-1_amd64.deb')}")
end

