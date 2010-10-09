#
# Author:: Thomas Bishop (<bishop.thomas@gmail.com>)
# Copyright:: Copyright (c) 2010 Thomas Bishop
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

describe Chef::Knife::Status do
  before do
    @query = mock("Chef::Search::Query")
    Chef::Search::Query.stub!(:new).and_return(@query)

    @node_1 = Chef::Node.new()
    @node_1.name('node1')
    @node_1['platform'] = 'ubuntu'
    @node_1['platform_version'] = '9.10'
    @node_1['ipaddress'] = '192.168.1.10'

    @node_2 = Chef::Node.new()
    @node_2.name('node2')
    @node_2['platform'] = 'redhat'
    @node_2['platform_version'] = '5.4'
    @node_2['ipaddress'] = '192.168.1.11'

    @node_3 = Chef::Node.new()
    @node_3.name('node3')
    @node_3['platform'] = 'debian'
    @node_3['platform_version'] = '5.0'
    @node_3['ipaddress'] = '192.168.1.12'

    [@node_1, @node_2, @node_3].each do |node|
      node['ohai_time'] = Time.now.to_i
      node['fqdn'] = "#{node.name}.example.com"
      node.run_list = ["role[webserver]", "role[#{node.name}]"]
    end

    @node_4 = Chef::Node.new()
    @node_4.name('node_4')

    @node_5 = Chef::Node.new()
    @node_5.name('node_5')

    @stdout = StringIO.new
    $stdout = @stdout
  end

  describe "when there are no nodes" do
    before do
      @knife = Chef::Knife::Status.new
      @knife.config = { :run_list => true }
      @query.should_receive(:search).with(:node, "*:*")
    end

    it "should not display any output" do
      @knife.run
      @stdout.string.should == ''
    end
  end

  describe "when getting the status of multiple nodes based on a query" do
    before do
      @knife = Chef::Knife::Status.new(["role:webserver"])
      @query.should_receive(:search).with(:node, "role:webserver").and_yield(@node_1).and_yield(@node_2).and_yield(@node_3).and_yield(@node_4).and_yield(@node_5)
    end

    it "should display green text if the node checked in within the last hour" do
      @node_1['ohai_time'] = Time.now.to_i - 1800
      @knife.run 
      @stdout.string.should match /\e\[32m30 minutes\e\[0m ago, #{@node_1.name}/
    end

    it "should display yellow text if the node checked in exacly one hour ago" do
      @node_1['ohai_time'] = Time.now.to_i - 3600
      @knife.run 
      @stdout.string.should match /\e\[33m1 hour\e\[0m ago, #{@node_1.name}/
    end

    it "should display yellow text if the node checked in a couple of hours ago" do
      @node_1['ohai_time'] = Time.now.to_i - 7200
      @knife.run 
      @stdout.string.should match /\e\[33m2 hours\e\[0m ago, #{@node_1.name}/
    end

    it "should display red text if the node checked in over 24 hours ago" do
      @node_1['ohai_time'] = Time.now.to_i - 90000
      @knife.run 
      @stdout.string.should match /\e\[31m25 hours\e\[0m ago, #{@node_1.name}/
    end

    it "should display details about each of the nodes" do
      @knife.run

      [@node_1, @node_2, @node_3].each do |node|
        @stdout.string.should match /.+ago, #{node.name}.+#{node['platform']}.+#{node['platform_version']}.+#{node['fqdn']}.+#{node['ipaddress']}.*\n/
      end
    end

    it "should display the public hostname and ip address for ec2 nodes" do
      @node_1['ec2'] = {'public_hostname' => 'ec2-134-129-223-23.compute-1.amazonaws.com',
                        'public_ipv4' => '134.129.223.23'}
      @knife.run
      @stdout.string.should match /.+ago, #{@node_1.name}.+#{@node_1['platform']}.+#{@node_1['platform_version']}.+#{@node_1['ec2']['public_hostname']}.+#{@node_1['ec2']['public_ipv4']}.+\n/
    end

    it "should display the run_list" do
      @knife.config = { :run_list => true }
      @knife.run

      [@node_1, @node_2, @node_3].each do |node|
        @stdout.string.should match /.+#{node.name}.+#{Regexp.escape(node.run_list.to_s)}.+\n/
      end
    end

    it "should display nodes which haven't checked in with red text" do
      @knife.run
      @stdout.string.should match /\e\[31m#{@node_4.name} has never checked in.\e\[0m\n\e\[31m#{@node_5.name} has never checked in.\e\[0m\n.+/
    end

    it "should display the nodes sorted from the oldest check in to the most recent" do
      @node_2['ohai_time'] = Time.now.to_i - 3700
      @node_3['ohai_time'] = Time.now.to_i - 86400
      @knife.run 
      @stdout.string.should match /.+#{@node_4.name}.+\n.+#{@node_5.name}.+\n.+#{@node_3.name}.+\n.+#{@node_2.name}.+\n.+#{@node_1.name}.+\n$/
    end
  end
end