#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Copyright:: Copyright (c) 2009 Bryan McLellan
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

describe Chef::Provider::Service::Freebsd do
  before do
    @node = Chef::Node.new
    @node[:command] = {:ps => "ps -ax"}
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::Service.new("apache22")
    @new_resource.pattern("httpd")
    @new_resource.supports({:status => false})

    @current_resource = Chef::Resource::Service.new("apache22")

    @provider = Chef::Provider::Service::Freebsd.new(@new_resource,@run_context)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
  end
  
  describe "load_current_resource" do
    before(:each) do
      @stdout = StringIO.new(<<-PS_SAMPLE)
413  ??  Ss     0:02.51 /usr/sbin/syslogd -s
539  ??  Is     0:00.14 /usr/sbin/sshd
545  ??  Ss     0:17.53 sendmail: accepting connections (sendmail)
PS_SAMPLE
      @status = mock(:stdout => @stdout, :exitstatus => 0)
      @provider.stub!(:shell_out!).with(@node[:command][:ps]).and_return(@status)

      ::File.stub!(:exists?).and_return(false)
      ::File.stub!(:exists?).with("/usr/local/etc/rc.d/apache22").and_return(true)
      @lines = mock("lines")
      @lines.stub!(:each).and_yield("sshd_enable=\"YES\"").
                          and_yield("apache22_enable=\"YES\"")
      ::File.stub!(:open).and_return(@lines)

    end
  
    it "should create a current resource with the name of the new resource" do
      Chef::Resource::Service.should_receive(:new).and_return(@current_resource)
      @provider.load_current_resource
    end

    it "should set the current resources service name to the new resources service name" do
      @provider.load_current_resource
      @current_resource.service_name.should == @new_resource.service_name
    end

    describe "when the service supports status" do
      before do
        @new_resource.supports({:status => true})
      end

      it "should run '/etc/init.d/service_name status'" do
        @provider.should_receive(:shell_out).with("/usr/local/etc/rc.d/apache22 status").and_return(@status)
        @provider.load_current_resource
      end
  
      it "should set running to true if the the status command returns 0" do
        @provider.should_receive(:shell_out).with("/usr/local/etc/rc.d/apache22 status").and_return(@status)
        @current_resource.should_receive(:running).with(true)
        @provider.load_current_resource
      end

      it "should set running to false if the status command returns anything except 0" do
        @provider.should_receive(:shell_out).with("/usr/local/etc/rc.d/apache22 status").and_raise(Mixlib::ShellOut::ShellCommandFailed)
        @current_resource.should_receive(:running).with(false)
        @provider.load_current_resource
      end
    end

    describe "when a status command has been specified" do
      before do
        @new_resource.status_command("/bin/chefhasmonkeypants status")
      end

      it "should run the services status command if one has been specified" do
        @provider.should_receive(:shell_out).with("/bin/chefhasmonkeypants status").and_return(@status)
        @provider.load_current_resource
      end
    
    end

    it "should raise error if the node has a nil ps attribute and no other means to get status" do
      @node[:command] = {:ps => nil}
      @provider.define_resource_requirements
      lambda { @provider.process_resource_requirements(:any) }.should raise_error(Chef::Exceptions::Service)
    end

    it "should raise error if the node has an empty ps attribute and no other means to get status" do
      @node[:command] = {:ps => ""}
      @provider.define_resource_requirements
      lambda { @provider.process_resource_requirements(:any) }.should raise_error(Chef::Exceptions::Service)
    end
    
    describe "when executing assertions" do
      it "should verify that /etc/rc.conf exists" do
        ::File.should_receive(:exists?).with("/etc/rc.conf")
        @provider.stub!(:service_enable_variable_name).and_return("apache22_enable")
        @provider.load_current_resource
      end

      it "should raise an exception when init script is not found" do
        ::File.stub!(:exists?).and_return(false)
        @provider.load_current_resource
        @provider.define_resource_requirements 
        @provider.instance_variable_get("@rcd_script_found").should be_false
        lambda { @provider.process_resource_requirements(:any) }.should raise_error(Chef::Exceptions::Service)
      end

      it "update state when current resource enabled state could not be determined" do
        ::File.should_receive(:exists?).with("/etc/rc.conf").and_return false
        @provider.load_current_resource
        @provider.instance_variable_get("@enabled_state_found").should be_false
      end 

      it "update state when current resource enabled state could be determined" do
        ::File.should_receive(:exists?).with("/etc/rc.conf").and_return  true
        @provider.load_current_resource
        @provider.instance_variable_get("@enabled_state_found").should be_false
        @provider.instance_variable_get("@rcd_script_found").should be_true
        @provider.define_resource_requirements 
        lambda { @provider.process_resource_requirements(:any) }.should raise_error(Chef::Exceptions::Service,
          'Could not find name="service" line in /usr/local/etc/rc.d/apache22')
      end 

      it "should throw an exception if service line is missing from rc.d script" do

      end

    end

    describe "when we have a 'ps' attribute" do
      before do
        @node[:command] = {:ps => "ps -ax"}
      end

      it "should shell_out! the node's ps command" do
        @provider.should_receive(:shell_out!).with(@node[:command][:ps]).and_return(@status)
        @provider.load_current_resource
      end

      it "should read stdout of the ps command" do
        @provider.stub!(:shell_out!).and_return(@status)
        @stdout.should_receive(:each_line).and_return(true)
        @provider.load_current_resource
      end

      it "should set running to true if the regex matches the output" do
        @stdout.stub!(:each_line).and_yield("555  ??  Ss     0:05.16 /usr/sbin/cron -s").
                                  and_yield(" 9881  ??  Ss     0:06.67 /usr/local/sbin/httpd -DNOHTTPACCEPT")
        @provider.load_current_resource 
        @current_resource.running.should be_true
      end

      it "should set running to false if the regex doesn't match" do
        @provider.stub!(:shell_out!).and_return(@status)
        @provider.load_current_resource
        @current_resource.running.should be_false
      end

      it "should raise an exception if ps fails" do
        @provider.stub!(:shell_out!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
        @provider.load_current_resource
        @provider.define_resource_requirements
        lambda { @provider.process_resource_requirements(:any) }.should raise_error(Chef::Exceptions::Service)
      end
    end

    it "should return the current resource" do
      @provider.load_current_resource.should eql(@current_resource)
    end

    describe "when starting the service" do
      it "should call the start command if one is specified" do
        @new_resource.start_command("/etc/rc.d/chef startyousillysally")
        @provider.should_receive(:shell_out!).with("/etc/rc.d/chef startyousillysally")
        @provider.load_current_resource
        @provider.start_service()
      end

      it "should call '/usr/local/etc/rc.d/service_name faststart' if no start command is specified" do
        @provider.should_receive(:shell_out!).with("/usr/local/etc/rc.d/#{@new_resource.service_name} faststart")
        @provider.load_current_resource
        @provider.start_service()
      end
    end

    describe Chef::Provider::Service::Init, "stop_service" do
      it "should call the stop command if one is specified" do
        @new_resource.stop_command("/etc/init.d/chef itoldyoutostop")
        @provider.should_receive(:shell_out!).with("/etc/init.d/chef itoldyoutostop")
        @provider.load_current_resource
        @provider.stop_service()
      end

      it "should call '/usr/local/etc/rc.d/service_name faststop' if no stop command is specified" do
        @provider.should_receive(:shell_out!).with("/usr/local/etc/rc.d/#{@new_resource.service_name} faststop")
        @provider.load_current_resource
        @provider.stop_service()
      end
    end

    describe "when restarting a service" do
      it "should call 'restart' on the service_name if the resource supports it" do
        @new_resource.supports({:restart => true})
        @provider.should_receive(:shell_out!).with("/usr/local/etc/rc.d/#{@new_resource.service_name} fastrestart")
        @provider.load_current_resource
        @provider.restart_service()
      end

      it "should call the restart_command if one has been specified" do
        @new_resource.restart_command("/etc/init.d/chef restartinafire")
        @provider.should_receive(:shell_out!).with("/etc/init.d/chef restartinafire")
        @provider.load_current_resource
        @provider.restart_service()
      end
    end

  end

  describe Chef::Provider::Service::Freebsd, "enable_service" do
    before do
      @provider.current_resource = @current_resource
      @provider.stub!(:service_enable_variable_name).and_return("apache22_enable")
    end

    it "should should enable the service if it is not enabled" do
      @current_resource.stub!(:enabled).and_return(false)
      @provider.should_receive(:read_rc_conf).and_return([ "foo", "apache22_enable=\"NO\"", "bar" ])
      @provider.should_receive(:write_rc_conf).with(["foo", "bar", "apache22_enable=\"YES\""])
      @provider.enable_service()
    end
  
    it "should enable the service if it is not enabled and not already specified in the rc.conf file" do
      @current_resource.stub!(:enabled).and_return(false)
      @provider.should_receive(:read_rc_conf).and_return([ "foo", "bar" ])
      @provider.should_receive(:write_rc_conf).with(["foo", "bar", "apache22_enable=\"YES\""])
      @provider.enable_service()
    end

    it "should not enable the service if it is already enabled" do
      @current_resource.stub!(:enabled).and_return(true)
      @provider.should_not_receive(:write_rc_conf)
      @provider.enable_service
    end
  end

  describe Chef::Provider::Service::Freebsd, "disable_service" do
    before do
      @provider.current_resource = @current_resource
      @provider.stub!(:service_enable_variable_name).and_return("apache22_enable")
    end

    it "should should disable the service if it is not disabled" do
      @current_resource.stub!(:enabled).and_return(true)
      @provider.should_receive(:read_rc_conf).and_return([ "foo", "apache22_enable=\"YES\"", "bar" ])
      @provider.should_receive(:write_rc_conf).with(["foo", "bar", "apache22_enable=\"NO\""])
      @provider.disable_service()
    end

    it "should not disable the service if it is already disabled" do
      @current_resource.stub!(:enabled).and_return(false)
      @provider.should_not_receive(:write_rc_conf)
      @provider.disable_service()
    end
  end
end
