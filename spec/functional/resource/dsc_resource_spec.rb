#
# Author:: Jay Mundrawala (<jdm@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
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

require 'spec_helper'

describe Chef::Resource::DscResource, :windows_powershell_dsc_only do
  before(:all) do
    @ohai = Ohai::System.new
    @ohai.all_plugins(['platform', 'os', 'languages/powershell'])
  end

  let(:event_dispatch) { Chef::EventDispatch::Dispatcher.new }

  let(:node) {
    Chef::Node.new.tap do |n|
      n.consume_external_attrs(@ohai.data, {})
    end
  }

  let(:run_context) { Chef::RunContext.new(node, {}, event_dispatch) }

  let(:new_resource) {
    Chef::Resource::DscResource.new("dsc_resource_test", run_context)
  }

  context 'when Powershell does not support Invoke-DscResource'
  context 'when Powershell supports Invoke-DscResource'
  
end
