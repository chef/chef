#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
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

describe Chef::Resource::Service do
  let(:resource) { Chef::Resource::Service.new("chef") }

  it "does not set a provider unless node[:init_package] is defined as systemd" do
    expect(resource.provider).to eq(nil)
  end

  it "sets the service_name property as the name_property" do
    expect(resource.service_name).to eql("chef")
  end

  it "sets the default action as :nothing" do
    expect(resource.action).to eql([:nothing])
  end

  it "supports :disable, :enable, :mask, :reload, :restart, :start, :stop, :unmask actions" do
    expect { resource.action :disable }.not_to raise_error
    expect { resource.action :enable }.not_to raise_error
    expect { resource.action :mask }.not_to raise_error
    expect { resource.action :reload }.not_to raise_error
    expect { resource.action :restart }.not_to raise_error
    expect { resource.action :start }.not_to raise_error
    expect { resource.action :stop }.not_to raise_error
    expect { resource.action :unmask }.not_to raise_error
  end

  it "Uses the service_name property as the default for the pattern property" do
    resource.service_name "something"
    expect(resource.pattern).to eql("something")
  end

  it "accepts a String for the service name property" do
    resource.service_name "something"
    expect(resource.service_name).to eql("something")
  end

  it "accepts a String for the service pattern" do
    resource.pattern ".*"
    expect(resource.pattern).to eql(".*")
  end

  it "does not accept a regexp for the service pattern" do
    expect do
      resource.pattern(/.*/)
    end.to raise_error(ArgumentError)
  end

  it "accepts a String for the user property" do
    resource.user "fakey_fakerton"
    expect(resource.user).to eql("fakey_fakerton")
  end

  it "accepts an Array for the run_levels property" do
    resource.run_levels ["foo"]
    expect(resource.run_levels).to eql(["foo"])
  end

  it "accepts a Hash for the parameters property" do
    param_hash = { something: nil }
    resource.parameters param_hash
    expect(resource.parameters).to eql(param_hash)
  end

  it "accepts a String for the init_command property" do
    resource.init_command "/etc/init.d/chef"
    expect(resource.init_command).to eql("/etc/init.d/chef")
  end

  it "does not accept a regexp for the init_command property" do
    expect do
      resource.init_command(/.*/)
    end.to raise_error(ArgumentError)
  end

  it "accepts an array for options property" do
    resource.options ["-r", "-s"]
    expect(resource.options).to eql(["-r", "-s"])
  end

  it "accepts a String for options property" do
    resource.options "-r"
    expect(resource.options).to eql(["-r"])
  end

  it "accepts a String with multiple flags for options property" do
    resource.options "-r -s"
    expect(resource.options).to eql(["-r", "-s"])
  end

  it "does not accept a boolean for options property" do
    expect do
      resource.options true
    end.to raise_error(ArgumentError)
  end

  %w{restart_command start_command stop_command status_command reload_command}.each do |prop|
    it "accepts a String for the #{prop} property" do
      resource.send(prop, "service foo bar")
      expect(resource.send(prop)).to eql("service foo bar")
    end

    it "accepts false for #{prop} property" do
      resource.send(prop, false)
      expect(resource.send(prop)).to eql(false)
    end

    it "does not accept a regexp for the #{prop} property" do
      expect { resource.send(prop, /.*/) }.to raise_error(ArgumentError)
    end
  end

  it "accepts a String for priority property" do
    resource.priority "1"
    expect(resource.priority).to eql("1")
  end

  it "accepts an Integer for priority property" do
    resource.priority 1
    expect(resource.priority).to eql(1)
  end

  it "accepts an Integer for timeout property" do
    resource.timeout 1
    expect(resource.timeout).to eql(1)
  end

  it "defaults the timeout property to 900 (seconds)" do
    expect(resource.timeout).to eql(900)
  end

  %w{enabled running}.each do |prop|
    it "accepts true for #{prop} property" do
      resource.send(prop, true)
      expect(resource.send(prop)).to eql(true)
    end

    it "accepts false for #{prop} property" do
      resource.send(prop, false)
      expect(resource.send(prop)).to eql(false)
    end

    it "does not accept a String for #{prop} property" do
      expect { resource.send(prop, "poop") }.to raise_error(ArgumentError)
    end
  end

  it "defaults all the feature support to nil" do
    support_hash = { status: nil, restart: nil, reload: nil }
    expect(resource.supports).to eq(support_hash)
  end

  it "allows you to set what features this resource supports as an array" do
    support_array = %i{status restart}
    support_hash = { status: true, restart: true }
    resource.supports(support_array)
    expect(resource.supports).to eq(support_hash)
  end

  it "allows you to set what features this resource supports as a hash" do
    support_hash = { status: true, restart: true }
    resource.supports(support_hash)
    expect(resource.supports).to eq(support_hash)
  end

  describe "when it has pattern and supports" do
    before do
      resource.service_name("superfriend")
      resource.enabled(true)
      resource.running(false)
    end

    it "describes its state" do
      state = resource.state_for_resource_reporter
      expect(state[:enabled]).to eql(true)
      expect(state[:running]).to eql(false)
    end

    it "returns the service_name property as its identity" do
      expect(resource.identity).to eq("superfriend")
    end
  end
end
