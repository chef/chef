#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
#
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
require "chef/provider/user/useradd"

describe Chef::Provider::User::Linux do

  subject(:provider) do
    p = described_class.new(@new_resource, @run_context)
    p.current_resource = @current_resource
    p
  end

  supported_useradd_options = {
    "comment" => "-c",
    "gid" => "-g",
    "uid" => "-u",
    "shell" => "-s",
    "password" => "-p",
  }

  include_examples "a useradd-based user provider", supported_useradd_options

  describe "manage_home behavior" do
    before(:each) do
      @new_resource = Chef::Resource::User::LinuxUser.new("adam", @run_context)
      @current_resource = Chef::Resource::User::LinuxUser.new("adam", @run_context)
    end

    it "supports manage_home does not exist", chef: ">= 13" do
      expect( @new_resource.supports.key?(:manage_home) ).to be false
    end

    it "supports non_unique does not exist", chef: ">= 13" do
      expect( @new_resource.supports.key?(:non_unique) ).to be false
    end

    # supports is a method on the superclass so can't totally be removed, but we should aggressively NOP it to decisively break it
    it "disables the supports API", chef: ">= 13" do
      @new_resource.supports( { manage_home: true } )
      expect( @new_resource.supports.key?(:manage_home) ).to be false
    end

    it "sets supports manage_home to false" do
      expect( @new_resource.supports[:manage_home] ).to be false
    end

    it "sets supports non-unique to false" do
      expect( @new_resource.supports[:non_unique] ).to be false
    end

    it "throws a deprecation warning on setting supports[:manage_home]" do
      Chef::Config[:treat_deprecation_warnings_as_errors] = false
      expect(Chef).to receive(:log_deprecation).with("supports { manage_home: true } on the user resource is deprecated and will be removed in Chef 13, set manage_home: true instead")
      @new_resource.supports( { :manage_home => true } )
    end

    it "defaults manage_home to false" do
      expect( @new_resource.manage_home ).to be false
    end

    it "supports[:manage_home] (incorectly) acts like manage_home" do
      Chef::Config[:treat_deprecation_warnings_as_errors] = false
      @new_resource.supports({ manage_home: true })
      expect( provider.useradd_options ).to eql(["-m"])
    end

    it "supports[:manage_home] does not change behavior of manage_home: false", chef: ">= 13" do
      Chef::Config[:treat_deprecation_warnings_as_errors] = false
      @new_resource.supports({ manage_home: true })
      expect( provider.useradd_options ).to eql(["-M"])
    end

    it "by default manage_home is false and we use -M" do
      expect( provider.useradd_options ).to eql(["-M"])
    end

    it "setting manage_home to false includes -M" do
      @new_resource.manage_home false
      expect( provider.useradd_options ).to eql(["-M"])
    end

    it "setting manage_home to true includes -m" do
      @new_resource.manage_home true
      expect( provider.useradd_options ).to eql(["-m"])
    end
  end
end
