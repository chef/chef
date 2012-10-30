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

describe Chef::Knife::ClientShow do
  before(:each) do
    @knife = Chef::Knife::ClientShow.new
    @knife.name_args = [ 'adam' ]
    @client_mock = mock('client_mock')
  end

  describe 'run' do
    it 'should list the client' do
      Chef::ApiClient.should_receive(:load).with('adam').and_return(@client_mock)
      @knife.should_receive(:format_for_display).with(@client_mock)
      @knife.run
    end

    it 'should print usage and exit when a client name is not provided' do
      @knife.name_args = []
      @knife.should_receive(:show_usage)
      @knife.ui.should_receive(:fatal)
      lambda { @knife.run }.should raise_error(SystemExit)
    end
  end
end
