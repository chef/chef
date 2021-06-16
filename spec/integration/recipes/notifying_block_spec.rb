#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "spec_helper"
require "support/shared/integration/integration_helper"
require "chef/mixin/shell_out"

describe "notifying_block" do
  include IntegrationSupport
  include Chef::Mixin::ShellOut

  let(:chef_dir) { File.expand_path("../../..", __dir__) }
  let(:chef_client) { "bundle exec chef-client --minimal-ohai" }

  when_the_repository "notifying_block test one" do
    before do
      directory "cookbooks/x" do
        file "recipes/default.rb", <<-EOM
          notifying_block do
            log "gamma" do
              action :nothing
            end
            notify_group "alpha" do
              notifies :write, "log[gamma]", :delayed
              action :run
            end
            notify_group "beta" do
              notifies :write, "log[gamma]", :delayed
              action :run
            end
          end
          log "delta"
        EOM
      end
      file "config/client.rb", <<-EOM
        local_mode true
        cookbook_path "#{path_to("cookbooks")}"
        log_level :warn
      EOM
    end

    # implicitly tests -
    #  1. notifying block opens up a subcontext
    #  2. delayed notifications are de-dup'd in the subcontext
    #  3. delayed notifications (to resources inside the subcontext) are run at the end of the subcontext
    it "should run alpha, beta, gamma, and delta in that order" do
      result = shell_out("#{chef_client} -c \"#{path_to("config/client.rb")}\" --no-color -F doc -o 'x::default'", cwd: chef_dir)
      expect(result.stdout).to match(/\* notify_group\[alpha\] action run\s+\* notify_group\[beta\] action run\s+\* log\[gamma\] action write\s+Converging 1 resources\s+\* log\[delta\] action write/)
      result.error!
    end
  end

  when_the_repository "notifying_block test two" do
    before do
      directory "cookbooks/x" do
        file "resources/nb_test.rb", <<-EOM
          unified_mode true
          default_action :run
          provides :nb_test
          resource_name :nb_test

          action :run do
            notifying_block do
              notify_group "foo" do
                notifies :write, 'log[bar]', :delayed
                action :run
              end
            end
          end
        EOM
        file "recipes/default.rb", <<-EOM
          log "bar" do
            action :nothing
          end
          log "baz" do
            action :nothing
          end

          nb_test "testing" do
            notifies :write, 'log[baz]', :delayed
          end

          log "quux"
        EOM
      end
      file "config/client.rb", <<-EOM
        local_mode true
        cookbook_path "#{path_to("cookbooks")}"
        log_level :warn
      EOM
    end

    # implicitly tests -
    #  1. notifying block will correctly update wrapping new_resource updated_by_last_action status
    #  2. delayed notifications from a subcontext inside a resource will notify resources in their outer run_context
    it "should run foo, quux, bar, and baz in that order" do
      result = shell_out("#{chef_client} -c \"#{path_to("config/client.rb")}\" --no-color -F doc -o 'x::default'", cwd: chef_dir)
      expect(result.stdout).to match(/\* notify_group\[foo\] action run\s+\* log\[quux\] action write\s+\* log\[bar\] action write\s+\* log\[baz\] action write/)
      result.error!
    end
  end
end
