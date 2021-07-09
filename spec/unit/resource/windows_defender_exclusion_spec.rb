#
# Copyright:: Copyright (c) Chef Software Inc.
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

describe Chef::Resource::WindowsDefenderExclusion do
  let(:resource) { Chef::Resource::WindowsDefenderExclusion.new("fakey_fakerton") }

  it "sets resource name as :windows_defender_exclusion" do
    expect(resource.resource_name).to eql(:windows_defender_exclusion)
  end

  it "sets the default action as :add" do
    expect(resource.action).to eql([:add])
  end

  it "supports :add, :remove actions" do
    expect { resource.action :add }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
  end

  it "paths property defaults to []" do
    expect(resource.paths).to eql([])
  end

  it "paths coerces strings to arrays" do
    resource.paths "foo,bar"
    expect(resource.paths).to eq(%w{foo bar})
  end

  it "extensions property defaults to []" do
    expect(resource.extensions).to eql([])
  end

  it "extensions coerces strings to arrays" do
    resource.extensions "foo,bar"
    expect(resource.extensions).to eq(%w{foo bar})
  end

  it "process_paths property defaults to []" do
    expect(resource.process_paths).to eql([])
  end

  it "process_paths coerces strings to arrays" do
    resource.process_paths "foo,bar"
    expect(resource.process_paths).to eq(%w{foo bar})
  end
end
