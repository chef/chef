#
# Authors:: Richard Manyanza (liseki@nyikacraftsmen.com)
# Copyright:: Copyright (c) 2014 Richard Manyanza
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

describe Chef::ProviderResolver::Package::Freebsd do
  before(:each) do
    @node = {}
    @resource = Chef::Resource::Package.new("zsh")
    @resolver = Chef::ProviderResolver::Package::Freebsd.new(@node, @resource)
  end

  describe "if ports specified as source" do
    it "should resolve to Freebsd::Port" do
      @resource.source('ports')
      @resolver.resolve.should == Chef::Provider::Package::Freebsd::Port
    end
  end

  describe "if __Freebsd_version greater than or equal to 1000017" do
    it "should resolve to Freebsd::Pkgng" do
      [1000017, 1000018, 1000500, 1001001, 1100000].each do |__freebsd_version|
        @node[:os_version] = __freebsd_version
        @resolver.resolve.should == Chef::Provider::Package::Freebsd::Pkgng
      end
    end
  end

  describe "if pkgng enabled" do
    it "should resolve to Freebsd::Pkgng" do
      pkg_enabled = OpenStruct.new(:stdout => "yes\n")
      @resolver.should_receive(:shell_out!).with("make -V WITH_PKGNG", :env => nil).and_return(pkg_enabled)
      @resolver.resolve.should == Chef::Provider::Package::Freebsd::Pkgng
    end
  end

  describe "if __Freebsd_version less than 1000017 and pkgng not enabled" do
    it "should resolve to Freebsd::Pkg" do
      pkg_enabled = OpenStruct.new(:stdout => "\n")
      @resolver.stub(:shell_out!).with("make -V WITH_PKGNG", :env => nil).and_return(pkg_enabled)

      [1000016, 1000000, 901503, 902506, 802511].each do |__freebsd_version|
        @node[:os_version] == __freebsd_version
        @resolver.resolve.should == Chef::Provider::Package::Freebsd::Pkg
      end
    end
  end
end
