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

describe Chef::Knife::ConfigureClient do
  before do
    @knife = Chef::Knife::ConfigureClient.new
    Chef::Config[:chef_server_url] = 'https://chef.example.com'
    Chef::Config[:validation_client_name] = 'chef-validator'
    Chef::Config[:validation_key] = '/etc/chef/validation.pem'

    @stdout = StringIO.new
    @knife.ui.stub!(:stdout).and_return(@stdout)
  end

  describe 'run' do
    it 'should print usage and exit when a directory is not provided' do
      @knife.should_receive(:show_usage)
      @knife.ui.should_receive(:fatal).with(/must provide the directory/)
      lambda {
        @knife.run
      }.should raise_error SystemExit
    end

    describe 'when specifing a directory' do
      before do
        @knife.name_args = ['/home/bob/.chef']
        @client_file = StringIO.new
        @validation_file = StringIO.new
        File.should_receive(:open).with('/home/bob/.chef/client.rb', 'w').
                                   and_yield(@client_file)
        File.should_receive(:open).with('/home/bob/.chef/validation.pem', 'w').
                                   and_yield(@validation_file)
        IO.should_receive(:read).and_return('foo_bar_baz')
      end

      it 'should recursively create the directory' do
        FileUtils.should_receive(:mkdir_p).with('/home/bob/.chef')
        @knife.run
      end

      it 'should write out the config file' do
        FileUtils.stub!(:mkdir_p)
        @knife.run
        @client_file.string.should match /log_level\s+\:info/
        @client_file.string.should match /log_location\s+STDOUT/
        @client_file.string.should match /chef_server_url\s+'https\:\/\/chef\.example\.com'/
        @client_file.string.should match /validation_client_name\s+'chef-validator'/
      end

      it 'should write out the validation.pem file' do
        FileUtils.stub!(:mkdir_p)
        @knife.run
        @validation_file.string.should match /foo_bar_baz/
      end

      it 'should print information on what is being configured' do
        FileUtils.stub!(:mkdir_p)
        @knife.run
        @stdout.string.should match /creating client configuration/i
        @stdout.string.should match /writing client\.rb/i
        @stdout.string.should match /writing validation\.pem/i
      end
    end
  end

end
