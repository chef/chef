#
# Author:: Dheeraj Singh Dubey (<ddubey@chef.io>)
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

describe Chef::Resource::WindowsFont, :windows_only do
  let(:resource_name) { "Playmaker.ttf" }
  let(:resource_source) { "https://www.wfonts.com/download/data/2020/05/06/playmaker/Playmaker.ttf" }

  let(:run_context) do
    node = Chef::Node.new
    node.default[:platform] = ohai[:platform]
    node.default[:platform_version] = ohai[:platform_version]
    node.default[:os] = ohai[:os]
    events = Chef::EventDispatch::Dispatcher.new
    Chef::RunContext.new(node, {}, events)
  end

  subject do
    resource = Chef::Resource::WindowsFont.new(resource_name, run_context)
    resource.source resource_source
    resource
  end

  ## these were commented out because testing hangs in the verify pipeline with them enabled. WEIRD
  ## that needs to be addressed

  # it "installs font on first install" do
  #   subject.run_action(:install)
  #   expect(subject).to be_updated_by_last_action
  # end

  # it "does not install font when already installed" do
  #   subject.run_action(:install)
  #   expect(subject).not_to be_updated_by_last_action
  # end
end
