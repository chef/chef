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
require 'chef/knife/serve'
require 'chef/server_api'

describe 'knife serve' do
  include IntegrationSupport
  include KnifeSupport
  include AppServerSupport

  when_the_repository 'has a node named x' do
    before { file 'nodes/x.json', { 'foo' => 'bar' } }

    it 'knife serve serves up /organizations/chef/nodes/x' do
      exception = nil
      t = Thread.new do
        begin
          knife('serve --chef-zero-port=8889')
        rescue
          exception = $!
        end
      end
      begin
        Chef::Config.log_level = :debug
        Chef::Config.chef_server_url = 'http://localhost:8889/organizations/chef'
        Chef::Config.node_name = nil
        Chef::Config.client_key = nil
        api = Chef::ServerAPI.new
        api.get('nodes/x')['name'].should == 'x'
      rescue
        if exception
          raise exception
        else
          raise
        end
      ensure
        t.kill
      end
    end

    context 'and organization = foo' do
      before do
        Chef::Config.organization = 'foo'
      end

      it 'knife serve serves up /organizations/foo/nodes/x' do
        exception = nil
        t = Thread.new do
          begin
            knife('serve --chef-zero-port=8889')
          rescue
            exception = $!
          end
        end
        begin
          Chef::Config.log_level = :debug
          Chef::Config.chef_server_url = 'http://localhost:8889/organizations/foo'
          Chef::Config.node_name = nil
          Chef::Config.client_key = nil
          api = Chef::ServerAPI.new
          api.get('nodes/x')['name'].should == 'x'
        rescue
          if exception
            raise exception
          else
            raise
          end
        ensure
          t.kill
        end
      end
    end

    context 'and chef_zero.chef_11_osc_compat = true' do
      before do
        Chef::Config.chef_zero.chef_11_osc_compat = true
      end

      it 'knife serve serves up /nodes/x' do
        exception = nil
        t = Thread.new do
          begin
            knife('serve --chef-zero-port=8889')
          rescue
            exception = $!
          end
        end
        begin
          Chef::Config.log_level = :debug
          Chef::Config.chef_server_url = 'http://localhost:8889'
          Chef::Config.node_name = nil
          Chef::Config.client_key = nil
          api = Chef::ServerAPI.new
          api.get('nodes/x')['name'].should == 'x'
        rescue
          if exception
            raise exception
          else
            raise
          end
        ensure
          t.kill
        end
      end
    end
  end
end
