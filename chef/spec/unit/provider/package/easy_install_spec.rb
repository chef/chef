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

describe Chef::Provider::Package::EasyInstall do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::EasyInstallPackage.new('boto')
    @new_resource.version('1.8d')

    @current_resource = Chef::Resource::EasyInstallPackage.new('boto')
    @current_resource.version('1.8d')

    @provider = Chef::Provider::Package::EasyInstall.new(@new_resource, @run_context)
    Chef::Resource::Package.stub!(:new).and_return(@current_resource)

    @stdin = StringIO.new
    @stdout = StringIO.new
    @status = mock("Status", :exitstatus => 0)
    @stderr = StringIO.new
    @pid = 2342
    @provider.stub!(:popen4).and_return(@status)
  end

  describe "easy_install_binary_path" do
    it "should return a Chef::Provider::EasyInstall object" do
      provider = Chef::Provider::Package::EasyInstall.new(@node, @new_resource)
      provider.should be_a_kind_of(Chef::Provider::Package::EasyInstall)
    end

    it "should set the current resources package name to the new resources package name" do
      $stdout.stub!(:write)
      @current_resource.should_receive(:package_name).with(@new_resource.package_name)
      @provider.load_current_resource
    end

    it "should return a relative path to easy_install if no easy_install_binary is given" do
      @provider.easy_install_binary_path.should eql("easy_install")
    end

    it "should return a specific path to easy_install if a easy_install_binary is given" do
      @new_resource.should_receive(:easy_install_binary).and_return("/opt/local/bin/custom/easy_install")
      @provider.easy_install_binary_path.should eql("/opt/local/bin/custom/easy_install")
    end

  end

  describe "actions_on_package" do
    it "should run easy_install with the package name and version" do
      @provider.should_receive(:run_command).with({
        :command => "easy_install \"boto==1.8d\""
      })
      @provider.install_package("boto", "1.8d")
    end

    it "should run easy_install with the package name and version and specified options" do
      @provider.should_receive(:run_command).with({
        :command => "easy_install --always-unzip \"boto==1.8d\""
      })
      @new_resource.stub!(:options).and_return("--always-unzip")
      @provider.install_package("boto", "1.8d")
    end

    it "should run easy_install with the package name and version" do
      @provider.should_receive(:run_command).with({
        :command => "easy_install \"boto==1.8d\""
      })
      @provider.upgrade_package("boto", "1.8d")
    end

    it "should run easy_install -m with the package name and version" do
      @provider.should_receive(:run_command).with({
        :command => "easy_install -m boto"
      })
      @provider.remove_package("boto", "1.8d")
    end

    it "should run easy_install -m with the package name and version and specified options" do
      @provider.should_receive(:run_command).with({
        :command => "easy_install -x -m boto"
      })
      @new_resource.stub!(:options).and_return("-x")
      @provider.remove_package("boto", "1.8d")
    end

    it "should run easy_install -m with the package name and version" do
      @provider.should_receive(:run_command).with({
        :command => "easy_install -m boto"
      })
      @provider.purge_package("boto", "1.8d")
    end

  end
end
