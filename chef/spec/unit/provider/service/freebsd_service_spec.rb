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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper"))

describe Chef::Provider::Service::Freebsd do
  before do
    @node = Chef::Node.new
    @node[:command] = {:ps => "ps -ax"}
    @run_context = Chef::RunContext.new(@node, {})

    @new_resource = Chef::Resource::Service.new("apache22")
    @new_resource.pattern("httpd")
    @new_resource.supports({:status => false})

    @current_resource = Chef::Resource::Service.new("apache22")

    @provider = Chef::Provider::Service::Freebsd.new(@new_resource,@run_context)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
  end

  describe "load_current_resource" do
    before(:each) do
      @status = mock("Status", :exitstatus => 0)
      @provider.stub!(:popen4).and_return(@status)
      @stdin = nil
      @stdout = StringIO.new(<<-PS_SAMPLE)
413  ??  Ss     0:02.51 /usr/sbin/syslogd -s
539  ??  Is     0:00.14 /usr/sbin/sshd
545  ??  Ss     0:17.53 sendmail: accepting connections (sendmail)
PS_SAMPLE
      @stderr = nil
      @pid = nil

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
        @provider.should_receive(:run_command).with({:command => "/usr/local/etc/rc.d/apache22 status"})
        @provider.load_current_resource
      end

      it "should set running to true if the the status command returns 0" do
        @provider.stub!(:run_command).with({:command => "/usr/local/etc/rc.d/apache22 status"}).and_return(0)
        @current_resource.should_receive(:running).with(true)
        @provider.load_current_resource
      end

      it "should set running to false if the status command returns anything except 0" do
        @provider.stub!(:run_command).with({:command => "/usr/local/etc/rc.d/apache22 status"}).and_raise(Chef::Exceptions::Exec)
        @current_resource.should_receive(:running).with(false)
        @provider.load_current_resource
      end
    end

    describe "when a status command has been specified" do
      before do
        @new_resource.status_command("/bin/chefhasmonkeypants status")
      end

      it "should run the services status command if one has been specified" do
        @provider.should_receive(:run_command).with({:command => "/bin/chefhasmonkeypants status"})
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

    describe "when we have a 'ps' attribute" do
      before do
        @node[:command] = {:ps => "ps -ax"}
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
        @stdout.stub!(:each_line).and_yield("555  ??  Ss     0:05.16 /usr/sbin/cron -s").
                                  and_yield(" 9881  ??  Ss     0:06.67 /usr/local/sbin/httpd -DNOHTTPACCEPT")
        @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
        @provider.load_current_resource
        @current_resource.running.should be_true
      end

      it "should set running to false if the regex doesn't match" do
        @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
        @provider.load_current_resource
        @current_resource.running.should be_false
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
