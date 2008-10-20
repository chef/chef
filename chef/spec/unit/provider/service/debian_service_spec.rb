#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper"))

describe Chef::Provider::Service::Debian, "load_current_resource" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)

    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :enabled => false
    )

    @current_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :enabled => false
    )

    @provider = Chef::Provider::Service::Debian.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)

    @status = mock("Status", :exitstatus => 0)
    @provider.stub!(:popen4).and_return(@status)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)
    @stdout.stub!(:each_line).and_yield(" Removing any system startup links for /etc/init.d/puppet ...")
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
  end

  it "should popen4 'update-rc.d -n -f service_name'" do
    @provider.should_receive(:popen4).with("update-rc.d -n -f #{@current_resource.service_name} remove").and_return(@status)
    @provider.load_current_resource
  end
  
  it "should close stdin on the update-rc.d command" do
    @provider.should_receive(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @stdin.should_receive(:close).and_return(true)
    @provider.load_current_resource
  end

  it "should read the stdout of the update-rc.d command" do
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @stdout.should_receive(:each_line).and_return(true)
    @provider.load_current_resource
  end

  it "should set enabled to true if the regex matches" do
    @stdout.stub!(:each_line).and_yield(" Removing any system startup links for /etc/init.d/puppet ...").
                              and_yield("   /etc/rc0.d/K20puppet").
                              and_yield("   /etc/rc1.d/K20puppet").
                              and_yield("   /etc/rc2.d/S20puppet").
                              and_yield("   /etc/rc3.d/S20puppet").
                              and_yield("   /etc/rc4.d/S20puppet").
                              and_yield("   /etc/rc5.d/S20puppet").
                              and_yield("   /etc/rc6.d/K20puppet")
    @current_resource.should_recieve(:enabled).with(true)
    @provider.load_current_resource
  end

  it "should set enabled to false if the regex does not match" do
    @stdout.stub!(:each_line).and_yield(" Removing any system startup links for /etc/init.d/puppet ...")
    @current_resource.should_recieve(:enabled).with(false)
    @provider.load_current_resource
  end

  it "should raise an error if update-rc.d fails" do
    @status.stub!(:exitstatus).and_return(42)
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exception::Service)
  end 
end

describe Chef::Provider::Service::Debian, "enable_service" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef"
    )

    @provider = Chef::Provider::Service::Debian.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
  end

  it "should call update-rc.d 'service_name' defaults" do
    @provider.should_receive(:run_command).with({:command => "update-rc.d #{@new_resource.service_name} defaults"})
    @provider.enable_service(@new_resource.service_name)
  end
end

describe Chef::Provider::Service::Debian, "disable_service" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef"
    )

    @provider = Chef::Provider::Service::Debian.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
  end

  it "should call update-rc.d -f 'service_name' remove" do
    @provider.should_receive(:run_command).with({:command => "update-rc.d -f #{@new_resource.service_name} remove"})
    @provider.disable_service(@new_resource.service_name)
  end
end
