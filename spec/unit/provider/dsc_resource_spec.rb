#
# Author:: Jay Mundrawala (<jdm@chef.io>)
#
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

require 'chef'
require 'spec_helper'

describe Chef::Provider::DscResource do
  let (:events) { Chef::EventDispatch::Dispatcher.new }
  let (:run_context) { Chef::RunContext.new(node, {}, events) }
  let (:resource) { Chef::Resource::DscResource.new("dscresource", run_context) }
  let (:provider) do
    Chef::Provider::DscResource.new(resource, run_context)
  end

  context 'when Powershell does not support Invoke-DscResource' do
    let (:node) {
      node = Chef::Node.new
      node.automatic[:languages][:powershell][:version] = '4.0'
      node
    }

    it 'raises a NoProviderAvailable exception' do
      expect(provider).not_to receive(:meta_configuration)
      expect{provider.run_action(:run)}.to raise_error(
              Chef::Exceptions::NoProviderAvailable, /5\.0\.10018\.0/)
    end
  end

  context 'when Powershell supports Invoke-DscResource' do
    let (:node) {
      node = Chef::Node.new
      node.automatic[:languages][:powershell][:version] = '5.0.10018.0'
      node
    }

    context 'when RefreshMode is not set to Disabled' do
      let (:meta_configuration) { {'RefreshMode' => 'AnythingElse'}}

      it 'raises an exception' do
        expect(provider).to receive(:meta_configuration).and_return(
                                                             meta_configuration)
        expect { provider.run_action(:run) }.to raise_error(
          Chef::Exceptions::NoProviderAvailable, /Disabled/)
      end
    end

    context 'when RefreshMode is set to Disabled' do
      let (:meta_configuration) { {'RefreshMode' => 'Disabled'}}

      it 'does not update the resource if it is up to date' do
        expect(provider).to receive(:meta_configuration).and_return(
                                                             meta_configuration)
        expect(provider).to receive(:test_resource).and_return(true)
        provider.run_action(:run)
        expect(resource).not_to be_updated
      end

      it 'converges the resource if it is not up to date' do
        expect(provider).to receive(:meta_configuration).and_return(
                                                             meta_configuration)
        expect(provider).to receive(:test_resource).and_return(false)
        expect(provider).to receive(:set_resource)
        provider.run_action(:run)
        expect(resource).to be_updated
      end
    end
  end
end
