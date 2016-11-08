#
# Author:: Thom May (<thom@chef.io>)
# Author:: Tim Smith (<tim@chef.io>)
# Copyright:: Copyright (c) 2016 Chef Software, Inc.
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

describe Chef::Provider::AptPreference do
  let(:new_resource) { Chef::Resource::AptPreference.new("libmysqlclient16") }
  let(:provider) do
    node = Chef::Node.new
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, events)
    Chef::Provider::AptPreference.new(new_resource, run_context)
  end

  it "responds to load_current_resource" do
    expect(provider).to respond_to(:load_current_resource)
  end

  it "creates apt preferences directory if it does not exist" do
    provider.run_action(:update)
    expect(new_resource).to be_updated_by_last_action
    expect(File.exist?('/etc/apt/preferences.d')).to be true
    expect(File.directory?('/etc/apt/preferences.d')).to be true
  end

  it "cleans up legacy non-sanitized name files" do
    # something
  end

  it "creates an apt .pref file" do
    # something
  end

  it "creates an apt .pref file with a sanitized filename" do
    # something
  end
end
