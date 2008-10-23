#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
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

describe Chef::Provider::Template, "action_create" do
  before(:each) do
    @rest = mock(Chef::REST, { :get_rest => "/tmp/foobar" })
    @tempfile = mock(Tempfile, { :path => "/tmp/foo", :print => true, :close => true })
    Tempfile.stub!(:new).and_return(@tempfile)
    File.stub!(:read).and_return("monkeypoop")
    @rest.stub!(:get_rest).and_return(@tempfile)
    @resource = Chef::Resource::Template.new("seattle")
    @resource.path(File.join(File.dirname(__FILE__), "..", "..", "data", "seattle.txt"))
    @resource.source("http://foo")
    @node = Chef::Node.new
    @node.name "latte"
    @provider = Chef::Provider::Template.new(@node, @resource)
    @provider.stub!(:checksum).and_return("dad86c61eea237932f201009e5431609")
    @provider.current_resource = @resource.clone
    @provider.current_resource.checksum("dad86c61eea237932f201009e5431609")
    FileUtils.stub!(:cp).and_return(true)
  end
  
  def do_action_create
    Chef::REST.stub!(:new).and_return(@rest)    
    @provider.action_create
  end
  
  it "should get the template based on the resources source value" do
    @rest.should_receive(:get_rest).with(@resource.source, true).and_return(@tempfile)
    do_action_create
  end
  
  it "should set the checksum of the new resource to the value of the returned template" do
    @resource.should_receive(:checksum).with("dad86c61eea237932f201009e5431609").once
    @resource.should_receive(:checksum).twice
    do_action_create
  end
  
  it "should not copy the tempfile to the real file if the checksums match" do
    FileUtils.should_not_receive(:cp)
    do_action_create
  end
  
  it "should copy the tempfile to the real file if the checksums do not match" do
    @provider.stub!(:checksum).and_return("dad86c61eea237932f201009e5431607")
    FileUtils.should_receive(:cp).once
    @provider.stub!(:backup).and_return(true)
    do_action_create
  end
  
  it "should set the owner if provided" do
    @resource.owner("adam")
    @provider.should_receive(:set_owner).and_return(true)
    do_action_create
  end
  
  it "should set the group if provided" do
    @resource.group("adam")
    @provider.should_receive(:set_group).and_return(true)
    do_action_create
  end
  
  it "should set the mode if provided" do
    @resource.mode(0676)
    @provider.should_receive(:set_mode).and_return(true)
    do_action_create
  end
end

describe Chef::Provider::Template, "generate_url" do
  
  before(:each) do
    @resource = Chef::Resource::Template.new("seattle")
    @resource.cookbook_name = "daft"
    @resource.path(File.join(File.dirname(__FILE__), "..", "..", "data", "seattle.txt"))
    @node = Chef::Node.new
    @node.name "latte"
    @provider = Chef::Provider::Template.new(@node, @resource)
  end
  
  it "should return a raw url if it starts with http" do
    @provider.generate_url('http://foobar', "templates").should eql("http://foobar")
  end
  
  it "should return a composed url if it does not start with http" do
    Chef::Platform.stub!(:find_platform_and_version).and_return(["monkey", "1.0"])
    @node.fqdn("monkeynode")
    @provider.generate_url('default/something', "templates").should eql("cookbooks/daft/templates?id=default/something&platform=monkey&version=1.0&fqdn=monkeynode")
  end
end