require 'support/shared/integration/integration_helper'
require 'chef/mixin/shell_out'

describe "LWRPs with inline resources" do
  extend IntegrationSupport
  include Chef::Mixin::ShellOut

  let(:chef_dir) { File.join(File.dirname(__FILE__), "..", "..", "..", "bin") }

  # Invoke `chef-client` as `ruby PATH/TO/chef-client`. This ensures the
  # following constraints are satisfied:
  # * Windows: windows can only run batch scripts as bare executables. Rubygems
  # creates batch wrappers for installed gems, but we don't have batch wrappers
  # in the source tree.
  # * Other `chef-client` in PATH: A common case is running the tests on a
  # machine that has omnibus chef installed. In that case we need to ensure
  # we're running `chef-client` from the source tree and not the external one.
  # cf. CHEF-4914
  let(:chef_client) { "ruby #{chef_dir}/chef-client" }

  when_the_repository "has a cookbook with a nested LWRP" do
  	directory 'cookbooks/x' do

      file 'resources/do_nothing.rb', <<EOM
actions :create, :nothing
default_action :create
EOM
      file 'providers/do_nothing.rb', <<EOM
action :create do
end
EOM

  	  file 'resources/my_machine.rb', <<EOM
actions :create, :nothing
default_action :create
EOM
      file 'providers/my_machine.rb', <<EOM
use_inline_resources
action :create do
  x_do_nothing 'a'
  x_do_nothing 'b'
end
EOM

  	  file 'recipes/default.rb', <<EOM
x_my_machine "me"
x_my_machine "you"
EOM

  	end # directory 'cookbooks/x'

    it "should complete with success" do
      file 'config/client.rb', <<EOM
local_mode true
cookbook_path "#{path_to('cookbooks')}"
log_level :warn
EOM

      result = shell_out("#{chef_client} -c \"#{path_to('config/client.rb')}\" --no-color -F doc -o 'x::default'", :cwd => chef_dir)
      result.stdout.should include(<<EOM)
  * x_my_machine[me] action create
    * x_do_nothing[a] action create (up to date)
    * x_do_nothing[b] action create (up to date)
     (up to date)
  * x_my_machine[you] action create
    * x_do_nothing[a] action create (up to date)
    * x_do_nothing[b] action create (up to date)
     (up to date)
EOM
      result.error!
    end
  end
end
