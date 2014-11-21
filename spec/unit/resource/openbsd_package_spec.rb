#
# Authors:: AJ Christensen (<aj@opscode.com>)
#           Richard Manyanza (<liseki@nyikacraftsmen.com>)
#           Scott Bonds (<scott@ggr.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# Copyright:: Copyright (c) 2014 Richard Manyanza, Scott Bonds
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

describe Chef::Resource::OpenbsdPackage do

  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @resource = Chef::Resource::OpenbsdPackage.new("foo", @run_context)
  end

  describe "Initialization" do
    it "should return a Chef::Resource::OpenbsdPackage" do
      @resource.should be_a_kind_of(Chef::Resource::OpenbsdPackage)
    end

    it "should set the resource_name to :openbsd_package" do
      @resource.resource_name.should eql(:openbsd_package)
    end

    it "should not set the provider" do
      @resource.provider.should be_nil
    end
  end

end

