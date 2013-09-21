require 'support/shared/integration/integration_helper'
require 'chef/mixin/shell_out'

describe "chef-client" do
  extend IntegrationSupport
  include Chef::Mixin::ShellOut

  when_the_repository "has a cookbook with a no-op recipe" do
    file 'cookbooks/x/recipes/default.rb', ''

    it "should complete with success" do
      file 'config/client.rb', <<EOM
chef_zero.enabled true
cookbook_path "#{path_to('cookbooks')}"
checksum_path "#{path_to('config/checksums')}"
file_cache_path "#{path_to('config/cache')}"
file_backup_path "#{path_to('config/backup')}"
EOM

      chef_dir = File.join(File.dirname(__FILE__), "..", "..", "..", "bin")
      result = shell_out("chef-client -c \"#{path_to('config/client.rb')}\" -o 'x::default'", :cwd => chef_dir)
      result.error!
    end

    it "should complete with success when passed the -z flag" do
      file 'config/client.rb', <<EOM
chef_server_url 'http://omg.com/blah'
cookbook_path "#{path_to('cookbooks')}"
checksum_path "#{path_to('config/checksums')}"
file_cache_path "#{path_to('config/cache')}"
file_backup_path "#{path_to('config/backup')}"
EOM

      chef_dir = File.join(File.dirname(__FILE__), "..", "..", "..", "bin")
      result = shell_out("chef-client -c \"#{path_to('config/client.rb')}\" -o 'x::default' -z", :cwd => chef_dir)
      result.error!
    end

    it "should complete with success when passed the --zero flag" do
      file 'config/client.rb', <<EOM
chef_server_url 'http://omg.com/blah'
cookbook_path "#{path_to('cookbooks')}"
checksum_path "#{path_to('config/checksums')}"
file_cache_path "#{path_to('config/cache')}"
file_backup_path "#{path_to('config/backup')}"
EOM

      chef_dir = File.join(File.dirname(__FILE__), "..", "..", "..", "bin")
      result = shell_out("chef-client -c \"#{path_to('config/client.rb')}\" -o 'x::default' --zero", :cwd => chef_dir)
      result.error!
    end

    it "should complete with success when passed -z and --chef-zero-port" do
      file 'config/client.rb', <<EOM
chef_server_url 'http://omg.com/blah'
cookbook_path "#{path_to('cookbooks')}"
checksum_path "#{path_to('config/checksums')}"
file_cache_path "#{path_to('config/cache')}"
file_backup_path "#{path_to('config/backup')}"
EOM

      chef_dir = File.join(File.dirname(__FILE__), "..", "..", "..", "bin")
      result = shell_out("chef-client -c \"#{path_to('config/client.rb')}\" -o 'x::default' -z", :cwd => chef_dir)
      result.error!
    end
  end
end
