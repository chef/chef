#
# Author:: Joshua Timberman (<joshua@getchef.com>)
#
# Copyright 2014, Chef Software, Inc <legal@getchef.com>
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
require 'chef/mixin/homebrew_owner'

class ExampleHomebrewOwner
  include Chef::Mixin::HomebrewOwner
end

describe Chef::Mixin::HomebrewOwner do
  before(:each) do
    node.default['homebrew']['owner'] = nil
  end

  let(:homebrew_owner) { ExampleHomebrewOwner.new }
  let(:node) { Chef::Node.new }

  describe 'when the homebrew owner node attribute is set' do
    it 'raises an exception if the owner is root' do
      node.default['homebrew']['owner'] = 'root'
      expect { homebrew_owner.homebrew_owner(node) }.to raise_exception(Chef::Exceptions::CannotDetermineHomebrewOwner)
    end

    it 'returns the owner set by attribute' do
      node.default['homebrew']['owner'] = 'siouxsie'
      expect(homebrew_owner.homebrew_owner(node)).to eql('siouxsie')
    end
  end

  describe 'when the owner attribute is not set and we use sudo' do
    before(:each) do
      ENV.stub(:[]).with('SUDO_USER').and_return('john_lydon')
    end

    it 'uses the SUDO_USER environment variable' do
      expect(homebrew_owner.homebrew_owner(node)).to eql('john_lydon')
    end
  end

  describe 'when the owner attribute is not set and we arent using sudo' do
    before(:each) do
      ENV.stub(:[]).with('USER').and_return('sid_vicious')
      ENV.stub(:[]).with('SUDO_USER').and_return(nil)
    end

    it 'uses the current user' do
      expect(homebrew_owner.homebrew_owner(node)).to eql('sid_vicious')
    end
  end
end
