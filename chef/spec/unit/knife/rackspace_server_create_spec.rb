#
# Author:: Andrew Cole <andrew@9summer.com>
# Copyright (c) 2010 Opscode, Inc.
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
#

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))
require 'fog'

describe Chef::Knife::RackspaceServerCreate do
  before(:each) do
    @knife_rackspace_create = Chef::Knife::RackspaceServerCreate.new()
    @knife_rackspace_create.name_args = ['foo-name']
    @knife_rackspace_create.initial_sleep_delay = 0
  end

  describe "run" do
    before do
      @rackspace_connection = mock()
      @rackspace_servers = mock()

      @new_rackspace_server = mock()
      @new_server_addresses = mock()
      @new_server_addresses.stub!(:[]).with('public').and_return(['1.2.3.4'])
      @new_server_addresses.stub!(:[]).with('private')

      rackspace_server_attrib_assignments = { 
        :flavor_id= => 1,
        :image_id= => 49,
	:name= => 'my-server'
      }

      rackspace_server_attrib_assignments.each_pair do |attrib, value|
        @new_rackspace_server.should_receive(attrib).at_least(:once).with(value).and_return(value)
      end

      rackspace_server_attrib_prints = {
        :flavor_id => 1,
        :image_id => 49,
        :name => 'my-server'
      }

      rackspace_server_attrib_prints.each_pair do |attrib, value|
        @new_rackspace_server.should_receive(attrib).at_least(:once).and_return(value)
      end

      @new_rackspace_server.should_receive(:password).at_least(:once)
      @new_rackspace_server.should_receive(:addresses).at_least(:once).and_return(@new_server_addresses)
      @new_server_addresses.should_receive(:[]).at_least(:once)

      @new_rackspace_server.should_receive(:save).and_return(true)
      @new_rackspace_server.should_receive(:wait_for).and_return(true)

      @rackspace_servers.should_receive(:new).and_return(@new_rackspace_server)

      @rackspace_connection.should_receive(:servers).and_return(@rackspace_servers)

      Fog::Rackspace::Servers.should_receive(:new).and_return(@rackspace_connection)

      @knife_rackspace_create.stub!(:puts)
      @knife_rackspace_create.stub!(:print)

      @bootstrap = mock()
    end

    it "should set the bootstrap name_args to an array" do
      @bootstrap.should_receive(:name_args=) do |x|
        x.should be_a_kind_of(Array)
        x.should == @new_server_addresses['public']
      end

      Chef::Knife::Bootstrap.should_receive(:new).once.and_return(@bootstrap)

      @bootstrap.should_receive(:config).at_least(:once).and_return({})
      @bootstrap.should_receive(:run)

      @knife_rackspace_create.run
    end

    it "should retry to bootstrap if the ssh connection is refused" do
      @bootstrap.should_receive(:name_args=).twice

      Chef::Knife::Bootstrap.should_receive(:new).twice.and_return(@bootstrap)

      @bootstrap.should_receive(:config).at_least(:once).and_return({})
      @bootstrap.should_receive(:run).once.and_raise(Errno::ECONNREFUSED)
      @bootstrap.should_receive(:run).once

      @knife_rackspace_create.run
    end

    it "should retry to bootstrap if the ssh connection times out" do
      @bootstrap.should_receive(:name_args=).twice

      Chef::Knife::Bootstrap.should_receive(:new).twice.and_return(@bootstrap)

      @bootstrap.should_receive(:config).at_least(:once).and_return({})
      @bootstrap.should_receive(:run).once.and_raise(Errno::ETIMEDOUT)
      @bootstrap.should_receive(:run).once

      @knife_rackspace_create.run
    end
  end
end
