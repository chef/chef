#
# Author:: Daniel DeLeo (<dan@chef.io>)
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

require "knife_spec_helper"
require "support/shared/integration/integration_helper"
require "chef/mixin/shell_out"

describe "Knife cookbook API integration with IPv6", :workstation, :not_supported_on_gce do
  include IntegrationSupport
  include Chef::Mixin::ShellOut

  when_the_chef_server "is bound to IPv6" do
    let(:chef_zero_opts) { { host: "::1" } }

    let(:client_key) do
      <<~END_VALIDATION_PEM
        <redacted>
      END_VALIDATION_PEM
    end

    let(:cache_path) do
      Dir.mktmpdir
    end

    let(:chef_dir) { File.join(__dir__, "..", "..", "..", "knife", "bin") }
    let(:knife) { "ruby '#{chef_dir}/knife'" }

    let(:knife_config_flag) { "-c '#{path_to("config/knife.rb")}'" }

    # Some Solaris test platforms are too old for IPv6. These tests should not
    # otherwise be platform dependent, so exclude solaris
    context "and the chef_server_url contains an IPv6 literal", :not_supported_on_solaris do

      # This provides helper functions we need such as #path_to()
      when_the_repository "has the cookbook to be uploaded" do

        let(:knife_rb_content) do
          <<~END_CLIENT_RB
            chef_server_url "http://[::1]:8900"
            syntax_check_cache_path '#{cache_path}'
            client_key '#{path_to("config/knifeuser.pem")}'
            node_name 'whoisthisis'
            cookbook_path '#{CHEF_SPEC_DATA}/cookbooks'
          END_CLIENT_RB
        end

        before do
          file "config/knife.rb", knife_rb_content
          file "config/knifeuser.pem", client_key
        end

        it "successfully uploads a cookbook" do
          shell_out!("#{knife} cookbook upload apache2 #{knife_config_flag}", cwd: chef_dir)
          versions_list_json = Chef::HTTP::Simple.new("http://[::1]:8900").get("/cookbooks/apache2", "accept" => "application/json")
          versions_list = Chef::JSONCompat.from_json(versions_list_json)
          expect(versions_list["apache2"]["versions"]).not_to be_empty
        end

        context "and the cookbook has been uploaded to the server" do
          before do
            shell_out!("#{knife} cookbook upload apache2 #{knife_config_flag}", cwd: chef_dir)
          end

          it "downloads the cookbook" do
            shell_out!("#{knife} cookbook download apache2 #{knife_config_flag} -d #{cache_path}", cwd: chef_dir)
            expect(Dir["#{cache_path}/*"].map { |entry| File.basename(entry) }).to include("apache2-0.0.1")
          end
        end

      end
    end
  end
end
