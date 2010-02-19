#
# Author:: Jan Zimmek (<jan.zimmek@web.de>)
# Author:: AJ Christensen (<aj@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

# most of this code has been ripped from init_service_spec.rb
# and is only slightly modified to match "arch" needs.

describe Chef::Provider::Service::Arch, "load_current_resource" do
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

    @provider = Chef::Provider::Service::Arch.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)

    @status = mock("Status", :exitstatus => 0)
    @provider.stub!(:popen4).and_return(@status)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)
    @stdout.stub!(:each).and_yield("aj        7842  5057  0 21:26 pts/2    00:00:06 vi init.rb").
                         and_yield("aj        7903  5016  0 21:26 pts/5    00:00:00 /bin/bash").
                         and_yield("aj        8119  6041  0 21:34 pts/3    00:00:03 vi init_service_spec.rb")
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
    
    ::File.stub!(:exists?).with("/etc/rc.conf").and_return(true)
    ::File.stub!(:read).with("/etc/rc.conf").and_return("DAEMONS=(network apache sshd)")
    
  end

  it "should create a current resource with the name of the new resource" do
    Chef::Resource::Service.should_receive(:new).and_return(@current_resource)
    @provider.load_current_resource
  end

  it "should set the current resources service name to the new resources service name" do
    @current_resource.should_receive(:service_name).with(@new_resource.service_name)
    @provider.load_current_resource
  end

  describe "when the service supports status" do
    before do
      @new_resource.stub!(:supports).and_return({:status => true})
    end

    it "should run '/etc/rc.d/service_name status'" do
      @provider.should_receive(:run_command).with({:command => "/etc/rc.d/#{@current_resource.service_name} status"})
      @provider.load_current_resource
    end
  
    it "should set running to true if the the status command returns 0" do
      @provider.stub!(:run_command).with({:command => "/etc/rc.d/#{@current_resource.service_name} status"}).and_return(0)
      @current_resource.should_receive(:running).with(true)
      @provider.load_current_resource
    end

    it "should set running to false if the status command returns anything except 0" do
      @provider.stub!(:run_command).with({:command => "/etc/rc.d/#{@current_resource.service_name} status"}).and_raise(Chef::Exceptions::Exec)
      @current_resource.should_receive(:running).with(false)
      @provider.load_current_resource
    end
  end

  describe "when a status command has been specified" do
    before do
      @new_resource.stub!(:status_command).and_return("/etc/rc.d/chefhasmonkeypants status")
    end

    it "should run the services status command if one has been specified" do
      @provider.should_receive(:run_command).with({:command => "/etc/rc.d/chefhasmonkeypants status"})
      @provider.load_current_resource
    end
    
  end

  it "should set running to false if the node has a nil ps attribute" do
    @node.stub!(:[]).with(:command).and_return({:ps => nil})
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
  end

  it "should set running to false if the node has an empty ps attribute" do
    @node.stub!(:[]).with(:command).and_return(:ps => "")
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
  end

  it "should fail if file /etc/rc.conf does not exist" do
    ::File.stub!(:exists?).with("/etc/rc.conf").and_return(false)
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
  end

  it "should fail if file /etc/rc.conf does not contain DAEMONS array" do
    ::File.stub!(:read).with("/etc/rc.conf").and_return("")
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
  
  it "should return existing entries in DAEMONS array" do
    ::File.stub!(:read).with("/etc/rc.conf").and_return("DAEMONS=(network !apache ssh)")
    @provider.daemons.should == ['network', '!apache', 'ssh']
  end

end

describe Chef::Provider::Service::Arch, "enable_service" do
  before(:each) do
    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :running => false
    )
    @new_resource.stub!(:start_command).and_return(false)

    @provider = Chef::Provider::Service::Arch.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
  end

  it "should add chef to DAEMONS array" do
    ::File.stub!(:read).with("/etc/rc.conf").and_return("DAEMONS=(network)")
    @provider.should_receive(:update_daemons).with(['network', 'chef'])
    @provider.enable_service()
  end
end

describe Chef::Provider::Service::Arch, "disable_service" do
  before(:each) do
    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :running => false
    )
    @new_resource.stub!(:start_command).and_return(false)

    @provider = Chef::Provider::Service::Arch.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
  end

  it "should remove chef from DAEMONS array" do
    ::File.stub!(:read).with("/etc/rc.conf").and_return("DAEMONS=(network chef)")
    @provider.should_receive(:update_daemons).with(['network', '!chef'])
    @provider.disable_service()
  end
end


describe Chef::Provider::Service::Arch, "start_service" do
  before(:each) do
    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :running => false
    )
    @new_resource.stub!(:start_command).and_return(false)

    @provider = Chef::Provider::Service::Arch.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
  end
  
  it "should call the start command if one is specified" do
    @new_resource.stub!(:start_command).and_return("/etc/rc.d/chef startyousillysally")
    @provider.should_receive(:run_command).with({:command => "/etc/rc.d/chef startyousillysally"}).and_return(0)
    @provider.start_service()
  end

  it "should call '/etc/rc.d/service_name start' if no start command is specified" do
    @provider.should_receive(:run_command).with({:command => "/etc/rc.d/#{@new_resource.service_name} start"}).and_return(0)
    @provider.start_service()
  end 
end

describe Chef::Provider::Service::Arch, "stop_service" do
  before(:each) do
    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :running => false
    )
    @new_resource.stub!(:stop_command).and_return(false)

    @provider = Chef::Provider::Service::Arch.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
  end

  it "should call the stop command if one is specified" do
    @new_resource.stub!(:stop_command).and_return("/etc/rc.d/chef itoldyoutostop")
    @provider.should_receive(:run_command).with({:command => "/etc/rc.d/chef itoldyoutostop"}).and_return(0)
    @provider.stop_service()
  end

  it "should call '/etc/rc.d/service_name stop' if no stop command is specified" do
    @provider.should_receive(:run_command).with({:command => "/etc/rc.d/#{@new_resource.service_name} stop"}).and_return(0)
    @provider.stop_service()
  end
end

describe Chef::Provider::Service::Arch, "restart_service" do
  before(:each) do
    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :running => false
    )
    @new_resource.stub!(:restart_command).and_return(false)
    @new_resource.stub!(:supports).and_return({:restart => false})

    @provider = Chef::Provider::Service::Arch.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
  end

  it "should call 'restart' on the service_name if the resource supports it" do
    @new_resource.stub!(:supports).and_return({:restart => true})
    @provider.should_receive(:run_command).with({:command => "/etc/rc.d/#{@new_resource.service_name} restart"}).and_return(0)
    @provider.restart_service()
  end

  it "should call the restart_command if one has been specified" do
    @new_resource.stub!(:restart_command).and_return("/etc/rc.d/chef restartinafire")
    @provider.should_receive(:run_command).with({:command => "/etc/rc.d/#{@new_resource.service_name} restartinafire"}).and_return(0)
    @provider.restart_service()
  end

  it "should just call stop, then start when the resource doesn't support restart and no restart_command is specified" do
    @provider.should_receive(:stop_service)
    @provider.should_receive(:sleep).with(1)
    @provider.should_receive(:start_service)
    @provider.restart_service()
  end
end

describe Chef::Provider::Service::Arch, "reload_service" do
  before(:each) do
    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :running => false
    )
    @new_resource.stub!(:reload_command).and_return(false)
    @new_resource.stub!(:supports).and_return({:reload => false})

    @provider = Chef::Provider::Service::Arch.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
  end

  it "should call 'reload' on the service if it supports it" do
    @new_resource.stub!(:supports).and_return({:reload => true})
    @provider.should_receive(:run_command).with({:command => "/etc/rc.d/#{@new_resource.service_name} reload"}).and_return(0)
    @provider.reload_service()
  end

  it "should should run the user specified reload command if one is specified and the service doesn't support reload" do
    @new_resource.stub!(:reload_command).and_return("/etc/rc.d/chef lollerpants")
    @provider.should_receive(:run_command).with({:command => "/etc/rc.d/#{@new_resource.service_name} lollerpants"}).and_return(0)
    @provider.reload_service()
  end
end
