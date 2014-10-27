#
# Author:: Scott Bonds (scott@ggr.com)
# Copyright:: Copyright (c) 2014 Scott Bonds
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
require 'ostruct'

describe Chef::Provider::Package::Openbsd do

  before(:each) do
    @node = Chef::Node.new
    @node.default['kernel'] = {'name' => 'OpenBSD', 'release' => '5.5', 'machine' => 'amd64'}
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
  end

  describe "install a package" do
    before do
      @name = 'ihavetoes'
      @new_resource     = Chef::Resource::Package.new(@name)
      @current_resource = Chef::Resource::Package.new(@name)
      @provider = Chef::Provider::Package::Openbsd.new(@new_resource, @run_context)
      @provider.current_resource = @current_resource
    end
    it "should run the installation command" do
      expect(@provider).to receive(:shell_out!).with(
        "pkg_add -r #{@name}",
        :env=>{
          "PACKAGESITE" => "http://ftp.eu.openbsd.org/pub/OpenBSD/5.5/packages/amd64/",
          "LC_ALL" => nil
        }
      ) {OpenStruct.new :status => true}
      @provider.install_package(@name, nil)
    end
  end

  describe "delete a package" do
    before do
      @name = 'ihavetoes'
      @new_resource     = Chef::Resource::Package.new(@name)
      @current_resource = Chef::Resource::Package.new(@name)
      @provider = Chef::Provider::Package::Openbsd.new(@new_resource, @run_context)
      @provider.current_resource = @current_resource
    end
    it "should run the command to delete the installed package" do
      expect(@provider).to receive(:shell_out!).with(
        "pkg_delete #{@name}", :env=>nil
      ) {OpenStruct.new :status => true}
      @provider.remove_package(@name, nil)
    end
  end

end

