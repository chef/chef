require 'support/shared/integration/integration_helper'
require 'chef/mixin/shell_out'

describe "chef-client" do
  extend IntegrationSupport
  include Chef::Mixin::ShellOut

  context "with a no-op recipe in the run_list" do

    when_the_repository "has a cookbook with a no-op recipe" do
      file 'cookbooks/x/recipes/default.rb', ''

      it "should complete with success" do
        file 'config/client.rb', <<EOM
chef_zero.enabled true
client_key "#{path_to('config/client.pem')}"
validation_key nil
cookbook_path "#{path_to('cookbooks')}"
checksum_path "#{path_to('config/checksums')}"
file_cache_path "#{path_to('config/cache')}"
file_backup_path "#{path_to('config/backup')}"
EOM

        chef_dir = File.join(File.dirname(__FILE__), "..", "..", "..", "bin")
        result = shell_out("chef-client -c \"#{path_to('config/client.rb')}\" -o 'x::default' -l debug", :cwd => chef_dir)
        result.error!
      end

    end
  end
end
