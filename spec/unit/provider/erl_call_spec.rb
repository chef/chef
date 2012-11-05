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

require 'spec_helper'

describe Chef::Provider::ErlCall do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::ErlCall.new("test", @node)
    @new_resource.code("io:format(\"burritos\", []).")
    @new_resource.node_name("chef@localhost")
    @new_resource.name("test")

    @provider = Chef::Provider::ErlCall.new(@new_resource, @run_context)

    @provider.stub!(:popen4).and_return(@status)
    @stdin = StringIO.new
    @stdout = StringIO.new('{ok, woohoo}')
    @stderr = StringIO.new
    @pid = 2342999
  end

  it "should return a Chef::Provider::ErlCall object" do
    provider = Chef::Provider::ErlCall.new(@new_resource, @run_context)
    provider.should be_a_kind_of(Chef::Provider::ErlCall)
  end

  it "should return true" do
    @provider.load_current_resource.should eql(true)
  end

  describe "when running a distributed erl call resource" do
    before do
      @new_resource.cookie("nomnomnom")
      @new_resource.distributed(true)
      @new_resource.name_type("sname")
    end

    it "should write to stdin of the erl_call command" do
      expected_cmd = "erl_call -e -s -sname chef@localhost -c nomnomnom"
      @provider.should_receive(:popen4).with(expected_cmd, :waitlast => true).and_return([@pid, @stdin, @stdout, @stderr])
      Process.should_receive(:wait).with(@pid)

      @provider.action_run

      @stdin.string.should == "#{@new_resource.code}\n"
    end
  end

  describe "when running a local erl call resource" do
    before do
      @new_resource.cookie(nil)
      @new_resource.distributed(false)
      @new_resource.name_type("name")
    end

    it "should write to stdin of the erl_call command" do
      @provider.should_receive(:popen4).with("erl_call -e  -name chef@localhost ", :waitlast => true).and_return([@pid, @stdin, @stdout, @stderr])
      Process.should_receive(:wait).with(@pid)

      @provider.action_run

      @stdin.string.should == "#{@new_resource.code}\n"
    end
  end

end

