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

describe 'knife common options' do
  extend IntegrationSupport
  include KnifeSupport

  when_the_repository "has a node" do
    file 'nodes/x.json', {}

    before(:each) do
      if ChefZero::RSpec.server
        ChefZero::RSpec.server.stop
        ChefZero::RSpec.server = nil
      end
    end

    context 'When chef_zero.enabled is true' do
      before(:each) do
        Chef::Config.chef_zero.enabled = true
      end

      it 'knife raw /nodes/x should retrieve the role' do
        knife('raw /nodes/x').should_succeed /"name": "x"/
      end

      context 'And chef_zero.port is 9999' do
        before(:each) { Chef::Config.chef_zero.port = 9999 }
 
        it 'knife raw /nodes/x should retrieve the role' do
          knife('raw /nodes/x').should_succeed /"name": "x"/
          Chef::Config.chef_server_url.should == 'http://127.0.0.1:9999'
        end
      end
    end

    it 'knife raw -z /nodes/x retrieves the role' do
      knife('raw -z /nodes/x').should_succeed /"name": "x"/
    end

    it 'knife raw --zero /nodes/x retrieves the role' do
      knife('raw --zero /nodes/x').should_succeed /"name": "x"/
    end

    it 'knife raw -z --chef-zero-port=9999 /nodes/x retrieves the role' do
      knife('raw -z --chef-zero-port=9999 /nodes/x').should_succeed /"name": "x"/
      Chef::Config.chef_server_url.should == 'http://127.0.0.1:9999'
    end
  end
end
