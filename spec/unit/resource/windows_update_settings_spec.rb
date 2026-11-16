#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# Author:: Tim Smith (tsmith@chef.io)
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

describe Chef::Resource::WindowsUpdateSettings do
  let(:resource) { Chef::Resource::WindowsUpdateSettings.new("foobar") }

  it "sets resource name as :windows_update_settings" do
    expect(resource.resource_name).to eql(:windows_update_settings)
  end

  it "sets the default action as :set" do
    expect(resource.action).to eql([:set])
  end

  it "supports :set and legacy :enable actions" do
    expect { resource.action :set }.not_to raise_error
    expect { resource.action :enable }.not_to raise_error
  end

  it "raises an error if scheduled_install_day isn't a validate day" do
    expect { resource.scheduled_install_day "Saturday" }.not_to raise_error
    expect { resource.scheduled_install_day "Sunday" }.not_to raise_error
    expect { resource.scheduled_install_day "Extraday" }.to raise_error(ArgumentError)
  end

  it "raises an error if automatic_update_option isn't a validate option" do
    expect { resource.automatic_update_option 2 }.not_to raise_error
    expect { resource.automatic_update_option :notify }.not_to raise_error
    expect { resource.automatic_update_option :nope }.to raise_error(ArgumentError)
  end

  it "coerces legacy Integer value in automatic_update_option to friendly symbol" do
    resource.automatic_update_option 2
    expect(resource.automatic_update_option).to eql(:notify)
  end

  it "raises an error if scheduled_install_hour isn't a 24 hour clock hour" do
    expect { resource.scheduled_install_hour 2 }.not_to raise_error
    expect { resource.scheduled_install_hour 0 }.to raise_error(ArgumentError)
    expect { resource.scheduled_install_hour 25 }.to raise_error(ArgumentError)
  end

  it "raises an error if custom_detection_frequency isn't a valid frequency" do
    expect { resource.custom_detection_frequency 0 }.not_to raise_error
    expect { resource.custom_detection_frequency 23 }.to raise_error(ArgumentError)
  end

  describe "#wsus_registry_values" do
    let(:node) { Chef::Node.new }
    let(:events) { Chef::EventDispatch::Dispatcher.new }
    let(:run_context) { Chef::RunContext.new(node, {}, events) }
    let(:provider) do
      resource.run_context = run_context
      resource.provider_for_action(:set)
    end

    it "writes nothing when no WSUS server or target group is configured" do
      expect(provider.wsus_registry_values).to eq([])
    end

    it "writes TargetGroup only when a target group name is set" do
      resource.target_wsus_group_name "servers"
      expect(provider.wsus_registry_values).to eq(
        [{ name: "TargetGroup", type: :string, data: "servers" }]
      )
    end

    it "writes both WSUS server values when a server url is set" do
      resource.wsus_server_url "https://wsus.example.com"
      expect(provider.wsus_registry_values).to eq(
        [
          { name: "WUServer", type: :string, data: "https://wsus.example.com" },
          { name: "WUStatusServer", type: :string, data: "https://wsus.example.com" },
        ]
      )
    end

    it "never emits a value with nil data" do
      resource.target_wsus_group_name "servers"
      resource.wsus_server_url "https://wsus.example.com"
      expect(provider.wsus_registry_values.map { |v| v[:data] }).to all(be_a(String))
    end
  end
end
