#
# Author:: S.Cavallo (<smcavallo@hotmail.com>)
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
require "chef/resource/snap_package"
require "chef/provider/package/snap"
require "support/shared/unit/resource/static_provider_resolution"

describe Chef::Resource::SnapPackage, "initialize" do

  static_provider_resolution(
    resource: Chef::Resource::SnapPackage,
    provider: Chef::Provider::Package::Snap,
    name: :snap_package,
    action: :install,
    os: "linux"
  )

  let(:resource) { Chef::Resource::SnapPackage.new("foo") }

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

  it "supports all channel values" do
    expect { resource.channel "stable" }.not_to raise_error
    expect { resource.channel "edge" }.not_to raise_error
    expect { resource.channel "beta" }.not_to raise_error
    expect { resource.channel "candidate" }.not_to raise_error
    expect { resource.channel "latest/stable" }.not_to raise_error
  end
end
