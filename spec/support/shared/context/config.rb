
#
# Define config file setups for spec tests here.
# https://www.relishapp.com/rspec/rspec-core/docs/example-groups/shared-context
#

# Required chef files here:
require "chef/config"

# Basic config. Nothing fancy.
shared_context "default config options" do
  before do
    Chef::Config[:cache_path] = windows? ? 'C:\chef' : "/var/chef"
  end

  # Don't need to have an after block to reset the config...
  # The spec_helper.rb takes care of resetting the config state.
end
