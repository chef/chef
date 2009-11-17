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

describe Chef::Provider::Mdadm, "initialize" do

  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Mdadm",
      :null_object => true,
      :devices => ["/dev/sdz1","/dev/sdz2"],
      :name => "/dev/md1",
      :mount_point => "/dev/md1",
      :level => 1,
      :chunk => 256,
      :exists => false
    )

    @current_resource = mock("Chef::Resource::Mdadm",
      :null_object => true,
      :devices => ["/dev/sdz1","/dev/sdz2"],
      :name => "/dev/md1",
      :mount_point => "/dev/md1",
      :level => 1,
      :chunk => 256,
      :exists => false
    )
    @new_resource = mock("Chef::Resource", :null_object => true)
    @provider = Chef::Provider::Mdadm.new(@node, @new_resource)
    Chef::Resource::Mdadm.stub!(:new).and_return(@current_resource)

    @status = mock("Status", :exitstatus => 0)
    @provider.stub!(:popen4).and_return(@status)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
  end

  it "should return a Chef::Provider::Mdadm object" do
    provider = Chef::Provider::Mdadm.new(@node, @new_resource)
    provider.should be_a_kind_of(Chef::Provider::Mdadm)
  end

  it "should create a current resource with the name of the new resource" do
    Chef::Resource::Mdadm.should_receive(:new).and_return(@current_resource)
    @provider.load_current_resource()
  end

  it "should set the current resources mount point to the new resources mount point" do
    @current_resource.should_receive(:raid_device).with(@new_resource.raid_device)
    @provider.load_current_resource()
  end
end

describe Chef::Provider::Mdadm, "action_create" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Mdadm",
      :null_object => true,
      :devices => ["/dev/sdz1","/dev/sdz2"],
      :name => "/dev/md1",
      :mount_point => "/dev/md1",
      :level => 1,
      :chunk => 256,
      :exists => false
    )

    @current_resource = mock("Chef::Resource::Mdadm",
      :null_object => true,
      :devices => ["/dev/sdz1","/dev/sdz2"],
      :name => "/dev/md1",
      :mount_point => "/dev/md1",
      :level => 1,
      :chunk => 256,
      :exists => false
    )

    @provider = Chef::Provider::Mdadm.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:create).and_return(true)
  end

  it "should create the raid device if it doesnt exist" do
    @current_resource.stub!(:exists).and_return(false)
    @provider.action_create
  end

  it "should not create the raid device if it does exist" do
    @current_resource.stub!(:exists).and_return(true)
    @provider.action_create
  end
end

describe Chef::Provider::Mdadm, "action_assemble" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Mdadm",
      :null_object => true,
      :devices => ["/dev/sdz1","/dev/sdz2"],
      :name => "/dev/md1",
      :mount_point => "/dev/md1",
      :level => 1,
      :chunk => 256,
      :exists => false
    )

    @current_resource = mock("Chef::Resource::Mdadm",
      :null_object => true,
      :devices => ["/dev/sdz1","/dev/sdz2"],
      :name => "/dev/md1",
      :mount_point => "/dev/md1",
      :level => 1,
      :chunk => 256,
      :exists => false
    )

    @provider = Chef::Provider::Mdadm.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:assemble).and_return(true)
  end

  it "should assemble the raid device if it doesnt exist" do
    @current_resource.stub!(:exists).and_return(false)
    @provider.action_assemble
  end

    it "should not assemble the raid device if it doesnt exist" do
    @current_resource.stub!(:exists).and_return(true)
    @provider.action_assemble
  end
end

describe Chef::Provider::Mdadm, "action_stop" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Mdadm",
      :null_object => true,
      :devices => ["/dev/sdz1","/dev/sdz2"],
      :name => "/dev/md1",
      :mount_point => "/dev/md1",
      :level => 1,
      :chunk => 256,
      :exists => false
    )

    @current_resource = mock("Chef::Resource::Mdadm",
      :null_object => true,
      :devices => ["/dev/sdz1","/dev/sdz2"],
      :name => "/dev/md1",
      :mount_point => "/dev/md1",
      :level => 1,
      :chunk => 256,
      :exists => false
    )

    @provider = Chef::Provider::Mdadm.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:stop).and_return(true)
  end

  it "should not stop the raid device if it doesnt exist" do
    @current_resource.stub!(:exists).and_return(false)
    @provider.action_stop
  end

  it "should stop the raid device if it does exist" do
    @current_resource.stub!(:exists).and_return(true)
    @provider.action_stop
  end
end
