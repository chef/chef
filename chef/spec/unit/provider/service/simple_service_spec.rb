#
# Author:: Mathieu Sauve-Frankel <msf@kisoku.net>
# Copyright:: Copyright (c) 2009, Mathieu Sauve Frankel
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

describe Chef::Provider::Service::Simple, "load_current_resource" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @node.stub!(:[]).with(:command).and_return({:ps => "ps -ef"})

    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :running => false
    )
    @new_resource.stub!(:pattern).and_return("chef")
    @new_resource.stub!(:supports).and_return({:status => false})
    @new_resource.stub!(:status_command).and_return(false)

    @current_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :running => false
    )

    @provider = Chef::Provider::Service::Simple.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)

    @status = mock("Status", :exitstatus => 0)
    @provider.stub!(:popen4).and_return(@status)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)
    @stdout.stub!(:each).and_yield("aj        7842  5057  0 21:26 pts/2    00:00:06 vi init.rb").
                         and_yield("aj        7903  5016  0 21:26 pts/5    00:00:00 /bin/bash").
                         and_yield("aj        8119  6041  0 21:34 pts/3    00:00:03 vi simple_service_spec.rb")
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
  end
  
  it "should create a current resource with the name of the new resource" do
    Chef::Resource::Service.should_receive(:new).and_return(@current_resource)
    @provider.load_current_resource
  end

  it "should set the current resources service name to the new resources service name" do
    @current_resource.should_receive(:service_name).with(@new_resource.service_name)
    @provider.load_current_resource
  end

  it "should set running to false if the node has a nil ps attribute" do
    @node.stub!(:[]).with(:command).and_return({:ps => nil})
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
  end

  it "should set running to false if the node has an empty ps attribute" do
    @node.stub!(:[]).with(:command).and_return(:ps => "")
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
  end

  describe "when we have a 'ps' attribute" do
    before do
      @node.stub!(:[]).with(:command).and_return({:ps => "ps -ef"})
    end

    it "should popen4 the node's ps command" do
      @provider.should_receive(:popen4).with(@node[:command][:ps]).and_return(@status)
      @provider.load_current_resource
    end

    it "should read stdout of the ps command" do
      @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @stdout.should_receive(:each_line).and_return(true)
      @provider.load_current_resource
    end

    it "should set running to true if the regex matches the output" do
      @stdout.stub!(:each_line).and_yield("aj        7842  5057  0 21:26 pts/2    00:00:06 chef").
                                and_yield("aj        7842  5057  0 21:26 pts/2    00:00:06 poos")
      @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @current_resource.should_receive(:running).with(true)
      @provider.load_current_resource 
    end

    it "should set running to false if the regex doesn't match" do
      @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @current_resource.should_receive(:running).with(false)
      @provider.load_current_resource
    end

    it "should raise an exception if ps fails" do
      @status.stub!(:exitstatus).and_return(-1)
      lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
    end
  end

  it "should return the current resource" do
    @provider.load_current_resource.should eql(@current_resource)
  end

end

describe Chef::Provider::Service::Simple, "start_service" do
  before(:each) do
    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :start_command => "/etc/init.d/chef start",
      :running => false
    )
    @new_resource.stub!(:start_command).and_return(false)

    @provider = Chef::Provider::Service::Simple.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
  end
  
  it "should call the start command if one is specified" do
    @new_resource.stub!(:start_command).and_return("#{@new_resource.start_command}")
    @provider.should_receive(:run_command).with({:command => "#{@new_resource.start_command}"}).and_return(0)
    @provider.start_service()
  end

  it "should raise an exception if no start command is specified" do
    lambda { @provider.start_service() }.should raise_error(Chef::Exceptions::Service)
  end 
end

describe Chef::Provider::Service::Simple, "stop_service" do
  before(:each) do
    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :service_command => "/etc/init.d/chef stop",
      :running => false
    )
    @new_resource.stub!(:stop_command).and_return(false)

    @provider = Chef::Provider::Service::Simple.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
  end

  it "should call the stop command if one is specified" do
    @new_resource.stub!(:stop_command).and_return("#{@new_resource.stop_command}")
    @provider.should_receive(:run_command).with({:command => "#{@new_resource.stop_command}"}).and_return(0)
    @provider.stop_service()
  end

  it "should raise an exception if no stop command is specified" do
    lambda { @provider.stop_service() }.should raise_error(Chef::Exceptions::Service)
  end
end

describe Chef::Provider::Service::Simple, "restart_service" do
  before(:each) do
    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :restart_command => "/etc/init.d/chef restart",
      :running => false
    )
    @new_resource.stub!(:restart_command).and_return(false)
    @new_resource.stub!(:supports).and_return({:restart => false})

    @provider = Chef::Provider::Service::Simple.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
  end

  it "should call the restart command if one has been specified" do
    @new_resource.stub!(:restart_command).and_return("#{@new_resource.stop_command}")
    @provider.should_receive(:run_command).with({:command => "#{@new_resource.restart_command}"}).and_return(0)
    @provider.restart_service()
  end

  it "should just call stop, then start when the resource doesn't support restart and no restart_command is specified" do
    @provider.should_receive(:stop_service)
    @provider.should_receive(:sleep).with(1)
    @provider.should_receive(:start_service)
    @provider.restart_service()
  end
end

describe Chef::Provider::Service::Simple, "reload_service" do
  before(:each) do
    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :reload_command => "/etc/init.d/chef reload",
      :running => false
    )
    @new_resource.stub!(:reload_command).and_return(false)

    @provider = Chef::Provider::Service::Simple.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
  end

  it "should should run the user specified reload command if one is specified" do
    @new_resource.stub!(:reload_command).and_return("#{@new_resource.reload_command}")
    @provider.should_receive(:run_command).with({:command => "#{@new_resource.reload_command}"}).and_return(0)
    @provider.reload_service()
  end
end
