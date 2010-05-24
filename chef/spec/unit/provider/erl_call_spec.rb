#
# Author:: Joe Williams (<joe@joetify.com>)
# Copyright:: Copyright (c) 2009 Joe Williams
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

describe Chef::Provider::ErlCall, "action_run" do
  before(:each) do
    @node = Chef::Node.new
    @run_context = Chef::RunContext.new(@node, {})
    @new_resource = mock("Chef::Resource::ErlCall",
      :null_object => true,
      :code => "io:format(\"burritos\", []).",
      :cookie => "nomnomnom",
      :distributed => true,
      :name_type => "sname",
      :node_name => "chef@localhost",
      :name => "test"
    )

    @provider = Chef::Provider::ErlCall.new(@new_resource, @run_context)

    @status = mock("Status", :exitstatus => 0)
    @provider.stub!(:popen4).and_return(@status)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
  end

  it "should return a Chef::Provider::ErlCall object" do
    provider = Chef::Provider::ErlCall.new(@new_resource, @run_context)
    provider.should be_a_kind_of(Chef::Provider::ErlCall)
  end

  it "should return true" do
    @provider.load_current_resource.should eql(true)
  end

  it "should write to stdin of the erl_call command" do
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @provider.action_run
  end

end

describe Chef::Provider::ErlCall, "action_run" do
  before(:each) do
    @node = Chef::Node.new
    @run_context = Chef::RunContext.new(@node, {})
    @new_resource = mock("Chef::Resource::ErlCall",
      :null_object => true,
      :code => "io:format(\"burritos\", []).",
      :cookie => nil,
      :distributed => false,
      :name_type => "name",
      :node_name => "chef@localhost",
      :name => "test"
    )

    @provider = Chef::Provider::ErlCall.new(@new_resource, @run_context)

    @status = mock("Status", :exitstatus => 0)
    @provider.stub!(:popen4).and_return(@status)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
  end

  it "should return a Chef::Provider::ErlCall object" do
    provider = Chef::Provider::ErlCall.new(@new_resource, @run_context)
    provider.should be_a_kind_of(Chef::Provider::ErlCall)
  end

  it "should return true" do
    @provider.load_current_resource.should eql(true)
  end

  it "should write to stdin of the erl_call command" do
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @provider.action_run
  end

end
