#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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
require "support/shared/context/config"
require "chef/knife/raw"
require "chef/knife/show"

describe "knife raw", :workstation do
  include IntegrationSupport
  include KnifeSupport
  include AppServerSupport

  include_context "default config options"

  when_the_chef_server "has one of each thing" do
    before do
      client "x", "{}"
      cookbook "x", "1.0.0"
      data_bag "x", { "y" => "{}" }
      environment "x", "{}"
      node "x", "{}"
      role "x", "{}"
      user "x", "{}"
    end

    it "knife raw /nodes/x returns the node", :skip => (RUBY_VERSION < "1.9") do
      knife("raw /nodes/x").should_succeed <<EOM
{
  "name": "x",
  "json_class": "Chef::Node",
  "chef_type": "node",
  "chef_environment": "_default",
  "override": {

  },
  "normal": {
    "tags": [

    ]
  },
  "default": {

  },
  "automatic": {

  },
  "run_list": [

  ]
}
EOM
    end

    it "knife raw /blarghle returns 404" do
      knife("raw /blarghle").should_fail(/ERROR: Server responded with error 404 "Not Found\s*"/)
    end

    it "knife raw -m DELETE /roles/x succeeds", :skip => (RUBY_VERSION < "1.9") do
      knife("raw -m DELETE /roles/x").should_succeed <<EOM
{
  "name": "x",
  "description": "",
  "json_class": "Chef::Role",
  "chef_type": "role",
  "default_attributes": {

  },
  "override_attributes": {

  },
  "run_list": [

  ],
  "env_run_lists": {

  }
}
EOM
      knife("show /roles/x.json").should_fail "ERROR: /roles/x.json: No such file or directory\n"
    end

    it "knife raw -m PUT -i blah.txt /roles/x succeeds", :skip => (RUBY_VERSION < "1.9") do
      Tempfile.open("raw_put_input") do |file|
        file.write <<EOM
{
  "name": "x",
  "description": "eek",
  "json_class": "Chef::Role",
  "chef_type": "role",
  "default_attributes": {

  },
  "override_attributes": {

  },
  "run_list": [

  ],
  "env_run_lists": {

  }
}
EOM
        file.close

        knife("raw -m PUT -i #{file.path} /roles/x").should_succeed <<EOM
{
  "name": "x",
  "description": "eek",
  "json_class": "Chef::Role",
  "chef_type": "role",
  "default_attributes": {

  },
  "override_attributes": {

  },
  "run_list": [

  ],
  "env_run_lists": {

  }
}
EOM
        knife("show /roles/x.json").should_succeed <<EOM
/roles/x.json:
{
  "name": "x",
  "description": "eek"
}
EOM
      end
    end

    it "knife raw -m POST -i blah.txt /roles succeeds", :skip => (RUBY_VERSION < "1.9") do
      Tempfile.open("raw_put_input") do |file|
        file.write <<EOM
{
  "name": "y",
  "description": "eek",
  "json_class": "Chef::Role",
  "chef_type": "role",
  "default_attributes": {
  },
  "override_attributes": {
  },
  "run_list": [

  ],
  "env_run_lists": {
  }
}
EOM
        file.close

        knife("raw -m POST -i #{file.path} /roles").should_succeed <<EOM
{
  "uri": "#{Chef::Config.chef_server_url}/roles/y"
}
EOM
        knife("show /roles/y.json").should_succeed <<EOM
/roles/y.json:
{
  "name": "y",
  "description": "eek"
}
EOM
      end
    end

    context "When a server returns raw json" do
      before :each do
        Chef::Config.chef_server_url = "http://localhost:9018"
        app = lambda do |env|
          [200, { "Content-Type" => "application/json" }, ['{ "x": "y", "a": "b" }'] ]
        end
        @raw_server, @raw_server_thread = start_app_server(app, 9018)
      end

      after :each do
        @raw_server.shutdown if @raw_server
        @raw_server_thread.kill if @raw_server_thread
      end

      it "knife raw /blah returns the prettified json", :skip => (RUBY_VERSION < "1.9") do
        knife("raw /blah").should_succeed <<EOM
{
  "x": "y",
  "a": "b"
}
EOM
      end

      it "knife raw --no-pretty /blah returns the raw json" do
        knife("raw --no-pretty /blah").should_succeed <<EOM
{ "x": "y", "a": "b" }
EOM
      end
    end

    context "When a server returns text" do
      before :each do
        Chef::Config.chef_server_url = "http://localhost:9018"
        app = lambda do |env|
          [200, { "Content-Type" => "text" }, ['{ "x": "y", "a": "b" }'] ]
        end
        @raw_server, @raw_server_thread = start_app_server(app, 9018)
      end

      after :each do
        @raw_server.shutdown if @raw_server
        @raw_server_thread.kill if @raw_server_thread
      end

      it "knife raw /blah returns the raw text" do
        knife("raw /blah").should_succeed(<<EOM)
{ "x": "y", "a": "b" }
EOM
      end

      it "knife raw --no-pretty /blah returns the raw text" do
        knife("raw --no-pretty /blah").should_succeed(<<EOM)
{ "x": "y", "a": "b" }
EOM
      end
    end
  end
end
