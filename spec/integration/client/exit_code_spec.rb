
require "spec_helper"
require "support/shared/integration/integration_helper"
require "chef/mixin/shell_out"
require "tiny_server"
require "tmpdir"
require "chef/platform"
require "chef-utils/dist"

describe "chef-client" do

  include IntegrationSupport
  include Chef::Mixin::ShellOut

  let(:chef_dir) { File.join(__dir__, "..", "..", "..") }

  # Invoke `chef-client` as `ruby PATH/TO/chef-client`. This ensures the
  # following constraints are satisfied:
  # * Windows: windows can only run batch scripts as bare executables. Rubygems
  # creates batch wrappers for installed gems, but we don't have batch wrappers
  # in the source tree.
  # * Other `chef-client` in PATH: A common case is running the tests on a
  # machine that has omnibus chef installed. In that case we need to ensure
  # we're running `chef-client` from the source tree and not the external one.
  # cf. CHEF-4914
  let(:chef_client) { "bundle exec #{ChefUtils::Dist::Infra::CLIENT} --no-fork --minimal-ohai" }

  let(:critical_env_vars) { %w{PATH RUBYOPT BUNDLE_GEMFILE GEM_PATH}.map { |o| "#{o}=#{ENV[o]}" } .join(" ") }

  when_the_repository "uses RFC 062 defined exit codes" do

    def setup_client_rb
      file "config/client.rb", <<~EOM
        local_mode true
        cookbook_path "#{path_to("cookbooks")}"
      EOM
    end

    def run_chef_client_and_expect_exit_code(exit_code)
      shell_out!("#{chef_client} -c \"#{path_to("config/client.rb")}\" -o 'x::default'",
        cwd: chef_dir,
        returns: [exit_code])
    end

    context "has a cookbook" do
      context "with a library" do
        context "which cannot be loaded" do
          before do
            file "cookbooks/x/recipes/default.rb", ""
            file "cookbooks/x/libraries/error.rb", "require 'does/not/exist'"
          end

          it "exits with GENERIC_FAILURE, 1" do
            setup_client_rb
            run_chef_client_and_expect_exit_code 1
          end
        end
      end

      context "with a recipe" do
        context "which throws an error" do
          before { file "cookbooks/x/recipes/default.rb", "raise 'BOOM'" }

          it "exits with GENERIC_FAILURE, 1" do
            setup_client_rb
            run_chef_client_and_expect_exit_code 1
          end
        end

        context "with a recipe which calls Chef::Application.fatal with a non-RFC exit code" do
          before { file "cookbooks/x/recipes/default.rb", "Chef::Application.fatal!('BOOM', 123)" }

          it "exits with the GENERIC_FAILURE exit code, 1" do
            setup_client_rb
            run_chef_client_and_expect_exit_code 1
          end
        end

        context "with a recipe which calls Chef::Application.exit with a non-RFC exit code" do
          before { file "cookbooks/x/recipes/default.rb", "Chef::Application.exit!('BOOM', 231)" }

          it "exits with the GENERIC_FAILURE exit code, 1" do
            setup_client_rb
            run_chef_client_and_expect_exit_code 1
          end
        end

        context "when a reboot exception is raised (like from the reboot resource)" do
          before do
            file "cookbooks/x/recipes/default.rb", <<~EOM
              raise Chef::Exceptions::Reboot.new
            EOM
          end

          it "exits with REBOOT_SCHEDULED, 35" do
            setup_client_rb
            run_chef_client_and_expect_exit_code 35
          end
        end

        context "when an attempt to reboot fails (like from the reboot resource)" do
          before do
            file "cookbooks/x/recipes/default.rb", <<~EOM
              raise Chef::Exceptions::RebootFailed.new
            EOM
          end

          it "exits with REBOOT_FAILED, 41" do
            setup_client_rb
            run_chef_client_and_expect_exit_code 41
          end
        end
      end
    end
  end
end
