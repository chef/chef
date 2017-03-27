#
# Author:: Nathan Williams (<nath.e.will@gmail.com>)
# Copyright:: Copyright 2016, Nathan Williams
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

describe Chef::Resource::SystemdUnit do
  before(:each) do
    @resource = Chef::Resource::SystemdUnit.new("sysstat-collect.timer")
  end

  let(:unit_content_string) { "[Unit]\nDescription = Run system activity accounting tool every 10 minutes\n\n[Timer]\nOnCalendar = *:00/10\n\n[Install]\nWantedBy = sysstat.service\n" }

  let(:unit_content_hash) do
    {
      "Unit" => {
        "Description" => "Run system activity accounting tool every 10 minutes",
      },
      "Timer" => {
        "OnCalendar" => "*:00/10",
      },
      "Install" => {
        "WantedBy" => "sysstat.service",
      },
    }
  end

  it "creates a new Chef::Resource::SystemdUnit" do
    expect(@resource).to be_a_kind_of(Chef::Resource)
    expect(@resource).to be_a_kind_of(Chef::Resource::SystemdUnit)
  end

  it "should have a name" do
    expect(@resource.name).to eql("sysstat-collect.timer")
  end

  it "has a default action of nothing" do
    expect(@resource.action).to eql([:nothing])
  end

  it "supports appropriate unit actions" do
    expect { @resource.action :create }.not_to raise_error
    expect { @resource.action :delete }.not_to raise_error
    expect { @resource.action :enable }.not_to raise_error
    expect { @resource.action :disable }.not_to raise_error
    expect { @resource.action :mask }.not_to raise_error
    expect { @resource.action :unmask }.not_to raise_error
    expect { @resource.action :start }.not_to raise_error
    expect { @resource.action :stop }.not_to raise_error
    expect { @resource.action :restart }.not_to raise_error
    expect { @resource.action :reload }.not_to raise_error
    expect { @resource.action :wrong }.to raise_error(ArgumentError)
  end

  it "accepts boolean state properties" do
    expect { @resource.active false }.not_to raise_error
    expect { @resource.active true }.not_to raise_error
    expect { @resource.active "yes" }.to raise_error(ArgumentError)

    expect { @resource.enabled true }.not_to raise_error
    expect { @resource.enabled false }.not_to raise_error
    expect { @resource.enabled "no" }.to raise_error(ArgumentError)

    expect { @resource.masked true }.not_to raise_error
    expect { @resource.masked false }.not_to raise_error
    expect { @resource.masked :nope }.to raise_error(ArgumentError)

    expect { @resource.static true }.not_to raise_error
    expect { @resource.static false }.not_to raise_error
    expect { @resource.static "yep" }.to raise_error(ArgumentError)
  end

  it "accepts the content property" do
    expect { @resource.content nil }.not_to raise_error
    expect { @resource.content "test" }.not_to raise_error
    expect { @resource.content({}) }.not_to raise_error
    expect { @resource.content 5 }.to raise_error(ArgumentError)
  end

  it "accepts the user property" do
    expect { @resource.user nil }.not_to raise_error
    expect { @resource.user "deploy" }.not_to raise_error
    expect { @resource.user 5 }.to raise_error(ArgumentError)
  end

  it "accepts the triggers_reload property" do
    expect { @resource.triggers_reload true }.not_to raise_error
    expect { @resource.triggers_reload false }.not_to raise_error
    expect { @resource.triggers_reload "no" }.to raise_error(ArgumentError)
  end

  it "reports its state" do
    @resource.active true
    @resource.enabled true
    @resource.masked false
    @resource.static false
    @resource.content "test"
    state = @resource.state_for_resource_reporter
    expect(state[:active]).to eq(true)
    expect(state[:enabled]).to eq(true)
    expect(state[:masked]).to eq(false)
    expect(state[:static]).to eq(false)
    expect(state[:content]).to eq("test")
  end

  it "returns the unit name as its identity" do
    expect(@resource.identity).to eq("sysstat-collect.timer")
  end

  it "serializes to ini with a string-formatted content property" do
    @resource.content(unit_content_string)
    expect(@resource.to_ini).to eq unit_content_string
  end

  it "serializes to ini with a hash-formatted content property" do
    @resource.content(unit_content_hash)
    expect(@resource.to_ini).to eq unit_content_string
  end
end
