#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

describe Chef::Provider::User::Linux, linux_only: true do

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

    it "throws an error when trying to set supports manage_home: true" do
      expect { @new_resource.supports( manage_home: true ) }.to raise_error(NoMethodError)
    end

    it "throws an error when trying to set supports non_unique: true" do
      expect { @new_resource.supports( non_unique: true ) }.to raise_error(NoMethodError)
    end

    it "defaults manage_home to false" do
      expect( @new_resource.manage_home ).to be false
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

  describe "expire_date behavior" do
    before(:each) do
      @new_resource = Chef::Resource::User::LinuxUser.new("adam", @run_context)
      @current_resource = Chef::Resource::User::LinuxUser.new("adam", @run_context)
    end

    it "defaults expire_date to nil" do
      expect( @new_resource.expire_date ).to be nil
    end

    it "by default expire_date is nil and we use ''" do
      expect( provider.universal_options ).to eql([])
    end

    it "setting expire_date to nil includes ''" do
      @new_resource.expire_date nil
      expect( provider.universal_options ).to eql([])
    end

    it "setting expire_date to 1982-04-16 includes -e" do
      @new_resource.expire_date "1982-04-16"
      expect( provider.universal_options ).to eql(["-e", "1982-04-16"])
    end
  end

  describe "inactive behavior" do
    before(:each) do
      @new_resource = Chef::Resource::User::LinuxUser.new("adam", @run_context)
      @current_resource = Chef::Resource::User::LinuxUser.new("adam", @run_context)
    end

    it "defaults inactive to nil" do
      expect( @new_resource.inactive ).to be nil
    end

    it "by default inactive is nil and we use ''" do
      expect( provider.universal_options ).to eql([])
    end

    it "setting inactive to nil includes ''" do
      @new_resource.inactive nil
      expect( provider.universal_options ).to eql([])
    end

    it "setting inactive to 90 includes -f" do
      @new_resource.inactive 90
      expect( provider.universal_options ).to eql(["-f", 90])
    end
  end

  describe "compare_user_linux" do
    before(:each) do
      @new_resource = Chef::Resource::User::LinuxUser.new("notarealuser")
      @current_resource = Chef::Resource::User::LinuxUser.new("notarealuser")
    end

    let(:mapping) do
      {
        "username" => %w{notarealuser notarealuser},
        "comment" => ["Nota Realuser", "Not a Realuser"],
        "uid" => [1000, 1001],
        "gid" => [1000, 1001],
        "home" => ["/home/notarealuser", "/Users/notarealuser"],
        "shell" => ["/usr/bin/zsh", "/bin/bash"],
        "password" => %w{abcd 12345},
        "sensitive" => [true],
      }
    end

    %w{uid gid comment home shell password}.each do |property|
      it "should return true if #{property} doesn't match" do
        @new_resource.send(property, mapping[property][0])
        @current_resource.send(property, mapping[property][1])
        expect(provider.compare_user).to eql(true)
      end
    end

    it "should show a blank for password if sensitive set to true" do
      @new_resource.password mapping["password"][0]
      @current_resource.password mapping["password"][1]
      @new_resource.sensitive true
      @current_resource.sensitive true
      provider.compare_user
      expect(provider.change_desc).to eql(["change password from ******** to ********"])
    end

    %w{uid gid}.each do |property|
      it "should return false if string #{property} matches fixnum" do
        @new_resource.send(property, "100")
        @current_resource.send(property, 100)
        expect(provider.compare_user).to eql(false)
      end
    end

    it "should return false if the objects are identical" do
      expect(provider.compare_user).to eql(false)
    end

    it "should ignore differences in trailing slash in home paths" do
      @new_resource.home "/home/notarealuser"
      @current_resource.home "/home/notarealuser/"
      expect(provider.compare_user).to eql(false)
    end
  end
end
