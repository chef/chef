# Verifies recipes/_chef_client.rb: chef_client_config wrote client.rb, and the
# inline-generated trusted certificate was installed and trusted for TLS.
describe file("C:\\chef\\client.rb") do
  it { should exist }
  its("content") { should match(%r{chef_server_url "https://localhost/organizations/test"}) }
  its("content") { should match(/chef_license "accept"/) }
  its("content") { should match(%r{rubygems_url "https://rubygems.org/"}) }
end

# trusted_certs_dir/file_cache_path vary depending on how this node's
# client.rb was generated, so read the actual resolved values the recipe
# reported instead of guessing a hardcoded path.
config_paths_content = file("C:\\chef_arm_test\\chef_client_config_paths.txt").content
config_paths = config_paths_content.lines.each_with_object({}) do |line, acc|
  key, value = line.strip.split("=", 2)
  acc[key] = value if key
end

describe file("#{config_paths['trusted_certs_dir']}/localhost.crt") do
  it { should exist }
  its("content") { should match(/BEGIN CERTIFICATE/) }
end

# If the trust chain didn't work, the remote_file in the recipe would have
# failed to converge and this file would never have been written.
describe file("#{config_paths['file_cache_path']}/arm_index.html") do
  it { should exist }
  its("content") { should match(/trusted cert test OK/) }
end
