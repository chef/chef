#
# Author:: Ranjib Dey (<ranjib@linux.com>)
# Copyright:: Copyright (c) 2015 Ranjib Dey.
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

require 'spec_helper'

describe Chef::Provider::Composite do
  let(:events) do
    Chef::EventDispatch::Dispatcher.new
  end

  let(:run_context) do
    Chef::RunContext.new(Chef::Node.new, {}, events)
  end

  context 'updated' do
    let(:resource) do
      r = Chef::Resource::Composite.new('test')
      r.resources do
        ruby_block 'res 1' do
          block {}
        end

        ruby_block 'res 2' do
          block {}
          action :nothing
        end
      end
      r
    end
    it 'when any of the nested resource is updated' do
      provider = Chef::Provider::Composite.new(resource, run_context)
      provider.run_action(:run)
      expect(resource.updated?).to be(true)
    end
  end

  context 'not updated' do
    let(:resource) do
      r = Chef::Resource::Composite.new('test')
      r.resources do
        ruby_block 'res 1' do
          block {}
          action :nothing
        end

        ruby_block 'res 2' do
          block {}
          action :nothing
        end
      end
      r
    end
    it 'none of the nested resource is updated' do
      provider = Chef::Provider::Composite.new(resource, run_context)
      provider.run_action(:run)
      expect(resource.updated?).to be(false)
    end
  end
end
