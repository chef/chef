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

require "knife_spec_helper"
require "tiny_server"
require "support/shared/integration/integration_helper"
require "support/shared/context/config"
require "chef/knife/list"

describe "redirection", :workstation do
  include IntegrationSupport
  include KnifeSupport

  def start_tiny_server(real_chef_server_url, **server_opts)
    @server = TinyServer::Manager.new(**server_opts)
    @server.start
    @api = TinyServer::API.instance
    @api.clear

    @api.get("/roles", 302, nil, { "Content-Type" => "text", "Location" => "#{real_chef_server_url}/roles" }) do
    end
  end

  def stop_tiny_server
    @server.stop
    @server = @api = nil
  end

  include_context "default config options"

  when_the_chef_server "has a role" do
    before { role "x", {} }

    context "and another server redirects to it with 302" do
      before(:each) do
        real_chef_server_url = Chef::Config.chef_server_url
        Chef::Config.chef_server_url = "http://localhost:9000"
        start_tiny_server(real_chef_server_url)
      end

      after(:each) do
        stop_tiny_server
      end

      it "knife list /roles returns the role" do
        knife("list /roles").should_succeed "/roles/x.json\n"
      end
    end
  end
end
