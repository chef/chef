#
# Author:: Joshua Timberman (<joshua@getchef.com>)
# Copyright (c) 2014, Chef Software, Inc. <legal@getchef.com>
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

describe Chef::Resource::HomebrewPackage, 'initialize' do

  let(:resource) { Chef::Resource::HomebrewPackage.new('emacs') }

  it 'returns a Chef::Resource::HomebrewPackage' do
    expect(resource).to be_a_kind_of(Chef::Resource::HomebrewPackage)
  end

  it 'sets the resource_name to :homebrew_package' do
    expect(resource.resource_name).to eql(:homebrew_package)
  end

  it 'sets the provider to Chef::Provider::Package::Homebrew' do
    expect(resource.provider).to eql(Chef::Provider::Package::Homebrew)
  end

  it 'sets the homebrew_user to nil' do
    expect(resource.homebrew_user).to eql(nil)
  end

  shared_examples 'home_brew user set and returned' do
    it 'returns the configured homebrew_user' do
      resource.homebrew_user user
      expect(resource.homebrew_user).to eql(user)
    end
  end

  context 'homebrew_user is set' do
    let(:user) { 'Captain Picard' }
    include_examples 'home_brew user set and returned'

    context 'as an integer' do
      let(:user) { 1001 }
      include_examples 'home_brew user set and returned'
    end
  end

end
