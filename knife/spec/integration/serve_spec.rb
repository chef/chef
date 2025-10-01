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

require "support/shared/integration/integration_helper"
require "chef/knife/serve"
require "chef/server_api"

describe "knife serve", :workstation do
  include IntegrationSupport
  include KnifeSupport

  def with_knife_serve
    exception = nil
    t = Thread.new do

      knife("serve --chef-zero-port=8890")
    rescue
      exception = $!

    end
    begin
      Chef::Config.log_level = :debug
      Chef::Config.chef_server_url = "http://localhost:8890"
      Chef::Config.node_name = nil
      Chef::Config.client_key = nil
      api = Chef::ServerAPI.new
      yield api
    rescue
      if exception
        raise exception
      else
        raise
      end
    ensure
      t.kill
      sleep 0.5
    end
  end

  when_the_repository "also has one of each thing" do
    before do
      file "nodes/a_node_in_json.json", { "foo" => "bar" }
      file "nodes/a_node_in_ruby.rb", "name 'a_node_in_ruby'"
      file "roles/a_role_in_json.json", { "foo" => "bar" }
      file "roles/a_role_in_ruby.rb", "name 'a_role_in_ruby'"
    end

    %w{a_node_in_json a_node_in_ruby}.each do |file_type|
      context file_type do
        it "knife serve serves up /nodes" do
          with_knife_serve do |api|
            expect(api.get("nodes")).to have_key(file_type)
          end
        end
        it "knife serve serves up /nodes/#{file_type}" do
          with_knife_serve do |api|
            expect(api.get("nodes/#{file_type}")["name"]).to eq(file_type)
          end
        end
      end
    end

    %w{a_role_in_json a_role_in_ruby}.each do |file_type|
      context file_type do
        it "knife serve serves up /roles" do
          with_knife_serve do |api|
            expect(api.get("roles")).to have_key(file_type)
          end
        end
        it "knife serve serves up /roles/#{file_type}" do
          with_knife_serve do |api|
            expect(api.get("roles/#{file_type}")["name"]).to eq(file_type)
          end
        end
      end
    end
  end
end
