#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

describe Chef::Resource::Package do

  before(:each) do
    @resource = Chef::Resource::Package.new("emacs")
  end

  it "should create a new Chef::Resource::Package" do
    expect(@resource).to be_a_kind_of(Chef::Resource)
    expect(@resource).to be_a_kind_of(Chef::Resource::Package)
  end

  it "should set the package_name to the first argument to new" do
    expect(@resource.package_name).to eql("emacs")
  end

  it "should accept a string for the package name" do
    @resource.package_name "something"
    expect(@resource.package_name).to eql("something")
  end

  it "should accept a string for the version" do
    @resource.version "something"
    expect(@resource.version).to eql("something")
  end

  it "should accept a string for the response file" do
    @resource.response_file "something"
    expect(@resource.response_file).to eql("something")
  end

  it "should accept a hash for response file template variables" do
    @resource.response_file_variables({ :variables => true })
    expect(@resource.response_file_variables).to eql({ :variables => true })
  end

  it "should accept a string for the source" do
    @resource.source "something"
    expect(@resource.source).to eql("something")
  end

  it "should accept a string for the options" do
    @resource.options "something"
    expect(@resource.options).to eql(["something"])
  end

  it "should split options" do
    @resource.options "-a -b 'arg with spaces' -b \"and quotes\""
    expect(@resource.options).to eql(["-a", "-b", "arg with spaces", "-b", "and quotes"])
  end

  describe "when it has a package_name and version" do
    before do
      @resource.package_name("tomcat")
      @resource.version("10.9.8")
      @resource.options("-al")
    end

    it "describes its state" do
      state = @resource.state_for_resource_reporter
      expect(state[:version]).to eq("10.9.8")
      expect(state[:options]).to eq(["-al"])
    end

    it "returns the file path as its identity" do
      expect(@resource.identity).to eq("tomcat")
    end

    it "takes options as an array" do
      @resource.options [ "-a", "-l" ]
      expect(@resource.options).to eq(["-a", "-l" ])
    end
  end

  # String, Integer
  [ "600", 600 ].each do |val|
    it "supports setting a timeout as a #{val.class}" do
      @resource.timeout(val)
      expect(@resource.timeout).to eql(val)
    end
  end

end
