#
# Author:: Deepali Jagtap (deepali.jagtap@clogeny.com)
# Author:: Prabhu Das (prabhu.das@clogeny.com)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

describe Chef::Provider::Package::Aix do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::Package.new('samba.base')
    @new_resource.source('/tmp/samba.base')

    @provider = Chef::Provider::Package::Aix.new(@new_resource, @run_context)
    ::File.stub(:exists?).and_return(true)
  end

  describe 'assessing the current package status' do
    before do
      @bffinfo = "/usr/lib/objrepos:samba.base:3.3.12.0::COMMITTED:I:Samba for AIX:
  /etc/objrepos:samba.base:3.3.12.0::COMMITTED:I:Samba for AIX:"

      @status = double('Status', exitstatus: 0)
    end

    it 'should create a current resource with the name of new_resource' do
      @provider.stub(:popen4).and_return(@status)
      @provider.load_current_resource
      @provider.current_resource.name.should == 'samba.base'
    end

    it 'should set the current resource bff package name to the new resource bff package name' do
      @provider.stub(:popen4).and_return(@status)
      @provider.load_current_resource
      @provider.current_resource.package_name.should == 'samba.base'
    end

    it 'should raise an exception if a source is supplied but not found' do
      @provider.stub(:popen4).and_return(@status)
      ::File.stub(:exists?).and_return(false)
      @provider.define_resource_requirements
      @provider.load_current_resource
      lambda { @provider.process_resource_requirements }.should raise_error(Chef::Exceptions::Package)
    end

    it 'should get the source package version from lslpp if provided' do
      @stdout = StringIO.new(@bffinfo)
      @stdin, @stderr = StringIO.new, StringIO.new
      @provider.should_receive(:popen4).with('installp -L -d /tmp/samba.base').and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @provider.should_receive(:popen4).with('lslpp -lcq samba.base').and_return(@status)
      @provider.load_current_resource

      @provider.current_resource.package_name.should == 'samba.base'
      @new_resource.version.should == '3.3.12.0'
    end

    it 'should return the current version installed if found by lslpp' do
      @stdout = StringIO.new(@bffinfo)
      @stdin, @stderr = StringIO.new, StringIO.new
      @provider.should_receive(:popen4).with('installp -L -d /tmp/samba.base').and_return(@status)
      @provider.should_receive(:popen4).with('lslpp -lcq samba.base').and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @provider.load_current_resource
      @provider.current_resource.version.should == '3.3.12.0'
    end

    it 'should raise an exception if the source is not set but we are installing' do
      @new_resource = Chef::Resource::Package.new('samba.base')
      @provider = Chef::Provider::Package::Aix.new(@new_resource, @run_context)
      @provider.stub(:popen4).and_return(@status)
      lambda { @provider.run_action(:install) }.should raise_error(Chef::Exceptions::Package)
    end

    it 'should raise an exception if installp/lslpp fails to run' do
      @status = double('Status', exitstatus: -1)
      @provider.stub(:popen4).and_return(@status)
      lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Package)
    end

    it 'should return a current resource with a nil version if the package is not found' do
      @stdout = StringIO.new
      @provider.should_receive(:popen4).with('installp -L -d /tmp/samba.base').and_return(@status)
      @provider.should_receive(:popen4).with('lslpp -lcq samba.base').and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @provider.load_current_resource
      @provider.current_resource.version.should be_nil
    end
  end

  describe 'candidate_version' do
    it 'should return the candidate_version variable if already setup' do
      @provider.candidate_version = '3.3.12.0'
      @provider.should_not_receive(:popen4)
      @provider.candidate_version
    end

    it 'should lookup the candidate_version if the variable is not already set' do
      @status = double('Status', exitstatus: 0)
      @provider.should_receive(:popen4).and_return(@status)
      @provider.candidate_version
    end

    it 'should throw and exception if the exitstatus is not 0' do
      @status = double('Status', exitstatus: 1)
      @provider.stub(:popen4).and_return(@status)
      lambda { @provider.candidate_version }.should raise_error(Chef::Exceptions::Package)
    end

  end

  describe 'install and upgrade' do
    it 'should run installp -aYF -d with the package source to install' do
      @provider.should_receive(:run_command_with_systems_locale).with(
                                                                        command: 'installp -aYF -d /tmp/samba.base samba.base'
                                                                      )
      @provider.install_package('samba.base', '3.3.12.0')
    end

    it 'should run  when the package is a path to install' do
      @new_resource = Chef::Resource::Package.new('/tmp/samba.base')
      @provider = Chef::Provider::Package::Aix.new(@new_resource, @run_context)
      @new_resource.source.should == '/tmp/samba.base'
      @provider.should_receive(:run_command_with_systems_locale).with(
                                                                        command: 'installp -aYF -d /tmp/samba.base /tmp/samba.base'
                                                                      )
      @provider.install_package('/tmp/samba.base', '3.3.12.0')
    end

    it 'should run installp with -eLogfile option.' do
      @new_resource.stub(:options).and_return('-e/tmp/installp.log')
      @provider.should_receive(:run_command_with_systems_locale).with(
                                                                        command: 'installp -aYF  -e/tmp/installp.log -d /tmp/samba.base samba.base'
                                                                      )
      @provider.install_package('samba.base', '3.3.12.0')
    end
  end

  describe 'remove' do
    it 'should run installp -u samba.base to remove the package' do
      @provider.should_receive(:run_command_with_systems_locale).with(
                                                                        command: 'installp -u samba.base'
                                                                      )
      @provider.remove_package('samba.base', '3.3.12.0')
    end

    it 'should run installp -u -e/tmp/installp.log  with options -e/tmp/installp.log' do
      @new_resource.stub(:options).and_return('-e/tmp/installp.log')
      @provider.should_receive(:run_command_with_systems_locale).with(
                                                                        command: 'installp -u  -e/tmp/installp.log samba.base'
                                                                      )
      @provider.remove_package('samba.base', '3.3.12.0')
    end

  end
end
