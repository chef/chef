require 'support/shared/integration/integration_helper'
require 'chef/mixin/shell_out'

describe "chef-solo" do
  extend IntegrationSupport
  include Chef::Mixin::ShellOut

  context "with a no-op recipe in the run_list" do

    when_the_repository "has a cookbook with a no-op recipe" do
      directory 'cookbooks'
      directory 'cookbooks/x'
      directory 'cookbooks/x/recipes'
      file 'cookbooks/x/metadata.rb', 'version "1.0.0"'
      file 'cookbooks/x/recipes/default.rb', ''

      before do
        @chef_file_cache = Dir.mktmpdir('file_cache')
      end

      after do
        FileUtils.rm_rf(@chef_file_cache) if @chef_file_cache
      end

      it "should complete with success" do
        # prepare the solo config
        directory 'config'
        file 'config/solo.rb', <<EOM
cookbook_path "#{File.join(@repository_dir, 'cookbooks')}"
file_cache_path "#{@chef_file_cache}"
EOM
        config_file = canonicalize_path(File.join(@repository_dir, 'config', 'solo.rb'))

        chef_dir = File.join(File.dirname(__FILE__), "..", "..", "..", "bin")
        result = shell_out("chef-solo -c \"#{config_file}\" -o 'x::default' -l debug", :cwd => chef_dir)
        result.error!
      end

    end
  end
end
