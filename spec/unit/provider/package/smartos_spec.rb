#
# Author:: Trevor O (trevoro@joyent.com)
# Author:: Yukihiko Sawanobori (sawanoboriyu@higanworks.com)
# Copyright:: Copyright (c) 2012 Opscode
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
require 'ostruct'

describe Chef::Provider::Package::SmartOS, "load_current_resource" do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource     = Chef::Resource::Package.new("varnish")
    @current_resource = Chef::Resource::Package.new("varnish")


    @status = double("Status", :exitstatus => 0)
    @provider = Chef::Provider::Package::SmartOS.new(@new_resource, @run_context)
    allow(Chef::Resource::Package).to receive(:new).and_return(@current_resource)
    @stdin = StringIO.new
    @stdout = "varnish-2.1.5nb2\n"
    @stderr = StringIO.new
    @pid = 10
    @shell_out = OpenStruct.new(:stdout => @stdout, :stdin => @stdin, :stderr => @stderr, :status => @status, :exitstatus => 0)
  end

  describe "when loading current resource" do

    it "should create a current resource with the name of the new_resource" do
      expect(@provider).to receive(:shell_out!).and_return(@shell_out)
      expect(Chef::Resource::Package).to receive(:new).and_return(@current_resource)
      @provider.load_current_resource
    end

    it "should set the current resource package name" do
      expect(@provider).to receive(:shell_out!).and_return(@shell_out)
      expect(@current_resource).to receive(:package_name).with(@new_resource.package_name)
      @provider.load_current_resource
    end

    it "should set the installed version if it is installed" do
      expect(@provider).to receive(:shell_out!).and_return(@shell_out)
      @provider.load_current_resource
      expect(@current_resource.version).to eq("2.1.5nb2")
    end

    it "should set the installed version to nil if it's not installed" do
      out = OpenStruct.new(:stdout => nil)
      expect(@provider).to receive(:shell_out!).and_return(out)
      @provider.load_current_resource
      expect(@current_resource.version).to eq(nil)
    end


  end

  describe "candidate_version" do
    it "should return the candidate_version variable if already setup" do
      @provider.candidate_version = "2.1.1"
      expect(@provider).not_to receive(:shell_out!)
      @provider.candidate_version
    end

    it "should lookup the candidate_version if the variable is not already set (pkgin separated by spaces)" do
      search = double()
      expect(search).to receive(:each_line).
        and_yield("something-varnish-1.1.1   something varnish like\n").
        and_yield("varnish-2.3.4             actual varnish\n")
      @shell_out = double('shell_out!', :stdout => search)
      expect(@provider).to receive(:shell_out!).with('/opt/local/bin/pkgin', 'se', 'varnish', :env => nil, :returns => [0,1]).and_return(@shell_out)
      expect(@provider.candidate_version).to eq("2.3.4")
    end

    it "should lookup the candidate_version if the variable is not already set (pkgin separated by semicolons)" do
      search = double()
      expect(search).to receive(:each_line).
        and_yield("something-varnish-1.1.1;;something varnish like\n").
        and_yield("varnish-2.3.4;;actual varnish\n")
      @shell_out = double('shell_out!', :stdout => search)
      expect(@provider).to receive(:shell_out!).with('/opt/local/bin/pkgin', 'se', 'varnish', :env => nil, :returns => [0,1]).and_return(@shell_out)
      expect(@provider.candidate_version).to eq("2.3.4")
    end
  end

  describe "when manipulating a resource" do

    it "run pkgin and install the package" do
      out = OpenStruct.new(:stdout => nil)
      expect(@provider).to receive(:shell_out!).with("/opt/local/sbin/pkg_info", "-E", "varnish*", {:env => nil, :returns=>[0,1]}).and_return(@shell_out)
      expect(@provider).to receive(:shell_out!).with("/opt/local/bin/pkgin", "-y", "install", "varnish-2.1.5nb2", {:env=>nil}).and_return(out)
      @provider.load_current_resource
      @provider.install_package("varnish", "2.1.5nb2")
    end

  end

end
