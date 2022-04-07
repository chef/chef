client_rb = if os.windows?
              'C:\chef\client.rb'
            else
              "/etc/chef/client.rb"
            end

describe file(client_rb) do
  its("content") { should match(%r{chef_server_url "https://localhost"}) }
  its("content") { should match(/chef_license "accept"/) }
  its("content") { should match(%r{rubygems_url "https://rubygems.org/"}) }
  its("content") { should match(/require 'aws-sdk'/) }
end
