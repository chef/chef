#
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

describe Chef::Resource::HomebrewTap do

  let(:resource) { Chef::Resource::HomebrewTap.new("user/mytap") }

  it "has a resource name of :homebrew_tap" do
    expect(resource.resource_name).to eql(:homebrew_tap)
  end

  it "the tap_name property is the name_property" do
    expect(resource.tap_name).to eql("user/mytap")
  end

  it "sets the default action as :tap" do
    expect(resource.action).to eql([:tap])
  end

  it "supports :tap, :untap actions" do
    expect { resource.action :tap }.not_to raise_error
    expect { resource.action :untap }.not_to raise_error
  end

  it "fails if tap_name isn't in the USER/TAP format" do
    expect { resource.tap_name "mytap" }.to raise_error(ArgumentError)
  end
end
