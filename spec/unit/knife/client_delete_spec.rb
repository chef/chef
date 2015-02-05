#
# Author:: Thomas Bishop (<bishop.thomas@gmail.com>)
# Copyright:: Copyright (c) 2011 Thomas Bishop
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

describe Chef::Knife::ClientDelete do
  before(:each) do
    @knife = Chef::Knife::ClientDelete.new
    # defaults
    @knife.config = {
      :delete_validators => false
    }
    @knife.name_args = [ 'adam' ]
  end

  describe 'run' do
    it 'should delete the client' do
      expect(@knife).to receive(:delete_object).with(Chef::ApiClient, 'adam', 'client')
      @knife.run
    end

    it 'should print usage and exit when a client name is not provided' do
      @knife.name_args = []
      expect(@knife).to receive(:show_usage)
      expect(@knife.ui).to receive(:fatal)
      expect { @knife.run }.to raise_error(SystemExit)
    end
  end

  describe 'with a validator' do
    before(:each) do
      allow(Chef::Knife::UI).to receive(:confirm).and_return(true)
      allow(@knife).to receive(:confirm).and_return(true)
      @client = Chef::ApiClient.new
      expect(Chef::ApiClient).to receive(:load).and_return(@client)
    end

    it 'should delete non-validator client if --delete-validators is not set' do
      @knife.config[:delete_validators] = false
      expect(@client).to receive(:destroy).and_return(@client)
      expect(@knife).to receive(:msg)

      @knife.run
    end

    it 'should delete non-validator client if --delete-validators is set' do
      @knife.config[:delete_validators] = true
      expect(@client).to receive(:destroy).and_return(@client)
      expect(@knife).to receive(:msg)

      @knife.run
    end

    it 'should not delete validator client if --delete-validators is not set' do
      @client.validator(true)
      expect(@knife.ui).to receive(:fatal)
      expect { @knife.run}.to raise_error(SystemExit)
    end

    it 'should delete validator client if --delete-validators is set' do
      @knife.config[:delete_validators] = true
      expect(@client).to receive(:destroy).and_return(@client)
      expect(@knife).to receive(:msg)

      @knife.run
    end
  end
end
