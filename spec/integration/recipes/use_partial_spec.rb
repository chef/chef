#
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

  when_the_repository "has a cookbook with partial resources" do
    before do
      directory "cookbooks/x" do
        file "resources/_shared_properties.rb", <<-EOM
          property :content, String
        EOM
        file "resources/_action_helpers.rb", <<-EOM
          def printit(string)
            puts "DIDIT: \#{string}"
          end
        EOM
        file "resources/thing.rb", <<-EOM
          unified_mode true
          provides :thing
          use "shared_properties"
          action_class do
            use "action_helpers"
          end
          action :run do
            printit(new_resource.content)
          end
        EOM
        file "recipes/default.rb", <<~EOM
          thing "whatever" do
            content "stuff"
          end
        EOM
      end
      file "config/client.rb", <<-EOM
        local_mode true
        cookbook_path "#{path_to("cookbooks")}"
        log_level :warn
        always_dump_stacktrace true
      EOM
    end

    it "should run cleanly and print the output" do
      result = shell_out("#{chef_client} -c \"#{path_to("config/client.rb")}\" --no-color -F doc -o 'x::default'", cwd: chef_dir)
      expect(result.stdout).to match(/DIDIT: stuff/)
      result.error!
    end
  end

  when_the_repository "has a cookbook with partial resources done differently" do
    before do
      directory "cookbooks/x" do
        file "partials/_shared_properties.rb", <<-EOM
          property :content, String
        EOM
        file "partials/_action_partials.rb", <<-EOM
          def printit(string)
            puts "DIDIT: \#{string}"
          end
        EOM
        # this tests relative pathing, including the underscore and including the trailing .rb all work
        file "resources/thing.rb", <<-EOM
          unified_mode true

          provides :thing
          use "../partials/_shared_properties.rb"
          action_class do
            use "../partials/_action_partials.rb"
          end
          action :run do
            printit(new_resource.content)
          end
        EOM
        file "recipes/default.rb", <<~EOM
          thing "whatever" do
            content "stuff"
          end
        EOM
      end
      file "config/client.rb", <<-EOM
        local_mode true
        cookbook_path "#{path_to("cookbooks")}"
        log_level :warn
        always_dump_stacktrace true
      EOM
    end

    it "should run cleanly and print the output" do
      result = shell_out("#{chef_client} -c \"#{path_to("config/client.rb")}\" --no-color -F doc -o 'x::default'", cwd: chef_dir)
      expect(result.stdout).to match(/DIDIT: stuff/)
      result.error!
    end
  end
end
