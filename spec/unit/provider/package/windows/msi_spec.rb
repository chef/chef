#
# Author:: Bryan McLellan <btm@loftninjas.org>
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

require 'spec_helper'

describe Chef::Provider::Package::Windows::MSI, :windows_only do
  let(:node) { double('Chef::Node') }
  let(:events) { double('Chef::Events').as_null_object }  # mock all the methods
  let(:run_context) { double('Chef::RunContext', :node => node, :events => events) }
  let(:new_resource) { Chef::Resource::WindowsPackage.new('calculator.msi') }
  let(:provider) { Chef::Provider::Package::Windows::MSI.new(new_resource) }

  describe 'expand_options' do
    it 'returns an empty string if passed no options' do
      expect(provider.expand_options(nil)).to eql ''
    end

    it 'returns a string with a leading space if passed options' do
      expect(provider.expand_options('--train nope --town no_way')).to eql(' --train nope --town no_way')
    end
  end

  describe 'installed_version' do
    it 'returns the installed version' do
      provider.stub(:get_product_property).and_return('{23170F69-40C1-2702-0920-000001000000}')
      provider.stub(:get_installed_version).with('{23170F69-40C1-2702-0920-000001000000}').and_return('3.14159.1337.42')
      expect(provider.installed_version).to eql('3.14159.1337.42')
    end
  end

  describe 'package_version' do
    it 'returns the version of a package' do
      provider.stub(:get_product_property).with(/calculator.msi$/, 'ProductVersion').and_return(42)
      expect(provider.package_version).to eql(42)
    end
  end

  describe 'install_package' do
    # calls shell_out!
  end

  describe 'remove_package' do
    # calls shell_out!
  end
end
