#
# Author:: Adam Jacob (adam@opscode.com)
# Copyright:: Copyright (c) 2009 Opscode
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

describe Chef::Provider::Script, "action_run" do  
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Script",
      :null_object => true,
      :code => "$| = 1; print 'i like beans'",
      :interpreter => 'perl',
      :user => nil,
      :group => nil
    )
    @tempfile = mock("Tempfile", 
      :null_object => true, 
      :puts => true, 
      :close => true,
      :path => "/tmp/perlscript"
    )
    @fr = Chef::Resource::File.new(@tempfile.path, nil, @node)
    Chef::Resource::File.stub!(:new).and_return(@fr)
    @fr.stub!(:run_action).and_return(true)
    Tempfile.stub!(:new).with("chef-script").and_return(@tempfile)
    File.stub!(:chown).and_return(true)
    @provider = Chef::Provider::Script.new(@node, @new_resource)
    @provider.stub!(:run_command).and_return(true)
  end

  it "should create a new temp file for the script" do
    Tempfile.should_receive(:new).with("chef-script").and_return(@tempfile)
    @provider.action_run
  end

  it "should put the contents of the script in the temp file" do
    @tempfile.should_receive(:puts).with(@new_resource.code)
    @provider.action_run
  end
  
  it "should close the tempfile" do
    @tempfile.should_receive(:close)
    @provider.action_run
  end

  it "should create a new Chef::Resource::File for the tempfile" do
    Chef::Resource::File.should_receive(:new).with(@tempfile.path, nil, @node).and_return(@fr)
    @provider.action_run
  end
  
  it "should set the owner attribute on the file resource from the script user" do
    @fr.should_receive(:owner).with(@new_resource.user)
    @provider.action_run
  end
  
  it "should set the group attribute on the file resource from the script group" do
    @fr.should_receive(:group).with(@new_resource.group)
    @provider.action_run
  end
  
  it "should run the create action on the file resouce" do
    @fr.should_receive(:run_action).with(:create)
    @provider.action_run
  end
  
  it "should set the command to 'interpreter tempfile'" do
    @new_resource.should_receive(:command).with("#{@new_resource.interpreter} #{@tempfile.path}")
    @provider.action_run
  end

end

