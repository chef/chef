#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require 'support/shared/integration/integration_helper'
require 'chef/knife/raw'
require 'chef/knife/show'

describe 'knife raw' do
  extend IntegrationSupport
  include KnifeSupport

  when_the_chef_server "has one of each thing" do
    client 'x', '{}'
    cookbook 'x', '1.0.0', { 'metadata.rb' => 'version "1.0.0"' }
    data_bag 'x', { 'y' => '{}' }
    environment 'x', '{}'
    node 'x', '{}'
    role 'x', '{}'
    user 'x', '{}'

    it 'knife raw /nodes/x returns the node', :pending => (RUBY_VERSION < "1.9") do
      knife('raw /nodes/x').should_succeed <<EOM
{
  "name": "x",
  "json_class": "Chef::Node",
  "chef_type": "node",
  "chef_environment": "_default",
  "override": {
  },
  "normal": {
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

    it 'knife raw /blarghle returns 404' do
      knife('raw /blarghle').should_fail(/ERROR: Server responded with error 404 "Not Found"/)
    end

    it 'knife raw -m DELETE /roles/x succeeds', :pending => (RUBY_VERSION < "1.9") do
      knife('raw -m DELETE /roles/x').should_succeed <<EOM
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
      knife('show /roles/x.json').should_fail "ERROR: /roles/x.json: No such file or directory\n"
    end

    it 'knife raw -m PUT -i blah.txt /roles/x succeeds', :pending => (RUBY_VERSION < "1.9") do
      Tempfile.open('raw_put_input') do |file|
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
        knife('show /roles/x.json').should_succeed <<EOM
/roles/x.json:
{
  "name": "x",
  "description": "eek"
}
EOM
      end
    end

    it 'knife raw -m POST -i blah.txt /roles succeeds', :pending => (RUBY_VERSION < "1.9") do
      Tempfile.open('raw_put_input') do |file|
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
  "uri": "#{ChefZero::RSpec.server.url}/roles/y"
}
EOM
        knife('show /roles/y.json').should_succeed <<EOM
/roles/y.json:
{
  "name": "y",
  "description": "eek"
}
EOM
      end
    end
  end
end
