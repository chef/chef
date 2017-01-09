#
# Authors:: AJ Christensen (<aj@chef.io>)
#           Richard Manyanza (<liseki@nyikacraftsmen.com>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
# Copyright:: Copyright 2014-2016, Richard Manyanza.
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

require "spec_helper"
require "ostruct"

describe Chef::Resource::FreebsdPackage do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @resource = Chef::Resource::FreebsdPackage.new("foo", @run_context)
  end

  describe "Initialization" do
    it "should return a Chef::Resource::FreebsdPackage" do
      expect(@resource).to be_a_kind_of(Chef::Resource::FreebsdPackage)
    end

    it "should set the resource_name to :freebsd_package" do
      expect(@resource.resource_name).to eql(:freebsd_package)
    end

    it "should not set the provider" do
      expect(@resource.provider).to be_nil
    end
  end

  describe "Assigning provider after creation" do
    describe "if ports specified as source" do
      it "should be Freebsd::Port" do
        @resource.source("ports")
        @resource.after_created
        expect(@resource.provider).to eq(Chef::Provider::Package::Freebsd::Port)
      end
    end

    describe "if freebsd_version is greater than or equal to 1000017" do
      it "should be Freebsd::Pkgng" do
        [1000017, 1000018, 1000500, 1001001, 1100000].each do |freebsd_version|
          @node.automatic_attrs[:os_version] = freebsd_version
          @resource.after_created
          expect(@resource.provider).to eq(Chef::Provider::Package::Freebsd::Pkgng)
        end
      end
    end

    describe "if pkgng enabled" do
      it "should be Freebsd::Pkgng" do
        pkg_enabled = OpenStruct.new(:stdout => "yes\n")
        allow(@resource).to receive(:shell_out!).with("make", "-V", "WITH_PKGNG", :env => nil).and_return(pkg_enabled)
        @resource.after_created
        expect(@resource.provider).to eq(Chef::Provider::Package::Freebsd::Pkgng)
      end
    end

    describe "if freebsd_version is less than 1000017 and pkgng not enabled" do
      it "should be Freebsd::Pkg" do
        pkg_enabled = OpenStruct.new(:stdout => "\n")
        allow(@resource).to receive(:shell_out!).with("make", "-V", "WITH_PKGNG", :env => nil).and_return(pkg_enabled)

        [1000016, 1000000, 901503, 902506, 802511].each do |freebsd_version|
          @node.automatic_attrs[:os_version] = freebsd_version
          @resource.after_created
          expect(@resource.provider).to eq(Chef::Provider::Package::Freebsd::Pkg)
        end
      end
    end
  end
end
