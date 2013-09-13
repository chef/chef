require 'support/shared/integration/integration_helper'
require 'chef/mixin/shell_out'

describe "chef-solo" do
  extend IntegrationSupport
  include Chef::Mixin::ShellOut

  when_the_repository "has a cookbook with a no-op recipe" do
    file 'cookbooks/x/metadata.rb', 'version "1.0.0"'
    file 'cookbooks/x/recipes/default.rb', ''

    it "should complete with success" do
      file 'config/solo.rb', <<EOM
cookbook_path "#{path_to('cookbooks')}"
file_cache_path "#{path_to('config/cache')}"
EOM

      chef_dir = File.join(File.dirname(__FILE__), "..", "..", "..", "bin")
      result = shell_out("chef-solo -c \"#{path_to('config/solo.rb')}\" -o 'x::default' -l debug", :cwd => chef_dir)
      result.error!
    end

  end
end
