#
# Author:: Kaustubh Deorukhkar (<kaustubh@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require 'functional/resource/base'

describe Chef::Resource::Ifconfig, :unix_only do

  let(:new_resource) do
    new_resource = Chef::Resource::Ifconfig.new('10.10.0.1', run_context)
    new_resource
  end

  let(:provider) do
    provider = new_resource.provider_for_action(new_resource.action)
    provider
  end

  let(:current_resource) do
    provider.load_current_resource
  end

  def network_interface_en0
    case ohai[:platform]
    when :aix
      'en0'
    else
      'eth0'
    end
  end

  describe "#load_current_resource" do
    # test en0 interface
    it 'should load given interface' do
      new_resource.device network_interface_en0
      expect(current_resource.device).to eql(network_interface_en0)
      expect(current_resource.inet_addr).to match(/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/)
    end
  end

  describe "#action_add", ohai[:platform] != :aix do
    after do
      new_resource.run_action(:delete)
    end
    it "should add interface eth0:10 (vip)" do
      new_resource.device "eth0:10"
      new_resource.run_action(:add)
      expect(current_resource.device).to eql("eth0:10")
      expect(current_resource.inet_addr).to eql("10.10.0.1")
    end
  end
end