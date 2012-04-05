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

describe Chef::Knife::ClientReregister do
  before(:each) do
    @knife = Chef::Knife::ClientReregister.new
    @knife.name_args = [ 'adam' ]
    @client_mock = mock('client_mock')
    @client_mock.stub!(:save).and_return({ 'private_key' => 'foo_key' })
    Chef::ApiClient.stub!(:load).and_return(@client_mock)
    @stdout = StringIO.new
    @knife.ui.stub!(:stdout).and_return(@stdout)
  end

  describe 'run' do
    it 'should load and save the client' do
      Chef::ApiClient.should_receive(:load).with('adam').and_return(@client_mock)
      @client_mock.should_receive(:save).with(true).and_return({'private_key' => 'foo_key'})
      @knife.run
    end

    it 'should output the private key' do
      @knife.run
      @stdout.string.should match /foo_key/
    end

    it 'should print usage and exit when a client name is not provided' do
      @knife.name_args = []
      @knife.should_receive(:show_usage)
      @knife.ui.should_receive(:fatal)
      lambda { @knife.run }.should raise_error(SystemExit)
    end

    describe 'with -f or --file' do
      it 'should write the private key to a file' do
        @knife.config[:file] = '/tmp/monkeypants'
        filehandle = mock('Filehandle')
        filehandle.should_receive(:print).with('foo_key')
        File.should_receive(:open).with('/tmp/monkeypants', 'w').and_yield(filehandle)
        @knife.run
      end
    end
  end
end
