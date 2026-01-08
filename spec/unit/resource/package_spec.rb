#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
  let(:resource) { Chef::Resource::Package.new("emacs") }

  it "sets the package_name to the first argument to new" do
    expect(resource.package_name).to eql("emacs")
  end

  it "sets the default action as :install" do
    expect(resource.action).to eql([:install])
  end

  it "supports :install, :lock, :purge, :reconfig, :remove, :unlock, :upgrade actions" do
    expect { resource.action :install }.not_to raise_error
    expect { resource.action :lock }.not_to raise_error
    expect { resource.action :purge }.not_to raise_error
    expect { resource.action :reconfig }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
    expect { resource.action :unlock }.not_to raise_error
    expect { resource.action :upgrade }.not_to raise_error
  end

  it "accepts a string for the package name" do
    resource.package_name "something"
    expect(resource.package_name).to eql("something")
  end

  it "accepts a string for the version" do
    resource.version "something"
    expect(resource.version).to eql("something")
  end

  it "accepts a string for the source" do
    resource.source "something"
    expect(resource.source).to eql("something")
  end

  it "accepts a string for the options" do
    resource.options "something"
    expect(resource.options).to eql(["something"])
  end

  it "splits options" do
    resource.options "-a -b 'arg with spaces' -b \"and quotes\""
    expect(resource.options).to eql(["-a", "-b", "arg with spaces", "-b", "and quotes"])
  end

  describe "when it has a package_name and version" do
    before do
      resource.package_name("tomcat")
      resource.version("10.9.8")
      resource.options("-al")
    end

    it "describes its state" do
      state = resource.state_for_resource_reporter
      expect(state[:version]).to eq("10.9.8")
      expect(state[:options]).to eq(["-al"])
    end

    it "returns the file path as its identity" do
      expect(resource.identity).to eq("tomcat")
    end

    it "takes options as an array" do
      resource.options [ "-a", "-l" ]
      expect(resource.options).to eq(["-a", "-l" ])
    end
  end

  # String, Integer
  [ "600", 600 ].each do |val|
    it "supports setting a timeout as a #{val.class}" do
      resource.timeout(val)
      expect(resource.timeout).to eql(val)
    end
  end
end
