require "spec_helper"
require "support/shared/integration/integration_helper"
require "chef/mixin/shell_out"

describe "LWRPs" do
  include IntegrationSupport
  include Chef::Mixin::ShellOut

  let(:chef_dir) { File.expand_path("../../..", __dir__) }

  # Invoke `chef-client` as `ruby PATH/TO/chef-client`. This ensures the
  # following constraints are satisfied:
  # * Windows: windows can only run batch scripts as bare executables. Rubygems
  # creates batch wrappers for installed gems, but we don't have batch wrappers
  # in the source tree.
  # * Other `chef-client` in PATH: A common case is running the tests on a
  # machine that has omnibus chef installed. In that case we need to ensure
  # we're running `chef-client` from the source tree and not the external one.
  # cf. CHEF-4914
  let(:chef_client) { "bundle exec chef-client --minimal-ohai" }

  when_the_repository "has a cookbook named l-w-r-p" do
    before do
      directory "cookbooks/l-w-r-p" do

        file "resources/foo.rb", <<~EOM
          unified_mode true

          default_action :create
        EOM
        file "providers/foo.rb", <<~EOM
          action :create do
          end
        EOM

        file "recipes/default.rb", <<~EOM
          l_w_r_p_foo "me"
        EOM

      end # directory 'cookbooks/x'
    end

    it "should complete with success" do
      file "config/client.rb", <<~EOM
        local_mode true
        cookbook_path "#{path_to("cookbooks")}"
        log_level :warn
      EOM

      result = shell_out("#{chef_client} -c \"#{path_to("config/client.rb")}\" --no-color -F doc -o 'l-w-r-p::default'", cwd: chef_dir)
      expect(result.stdout).to match(/\* l_w_r_p_foo\[me\] action create \(up to date\)/)
      expect(result.stdout).not_to match(/WARN: You are overriding l_w_r_p_foo/)
      result.error!
    end
  end
end
