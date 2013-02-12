#
# Author:: Steven Danna (<steve@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc
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

describe Chef::Knife::UserReregister do
  before(:each) do
    Chef::Knife::UserReregister.load_deps
    @knife = Chef::Knife::UserReregister.new
    @knife.name_args = [ 'a_user' ]
    @user_mock = mock('user_mock', :private_key => "private_key")
    Chef::User.stub!(:load).and_return(@user_mock)
    @stdout = StringIO.new
    @knife.ui.stub!(:stdout).and_return(@stdout)
  end

  it 'prints usage and exits when a user name is not provided' do
    @knife.name_args = []
    @knife.should_receive(:show_usage)
    @knife.ui.should_receive(:fatal)
    lambda { @knife.run }.should raise_error(SystemExit)
  end

  it 'reregisters the user and prints the key' do
    @user_mock.should_receive(:reregister).and_return(@user_mock)
    @knife.run
    @stdout.string.should match( /private_key/ )
  end

  it 'writes the private key to a file when --file is specified' do
    @user_mock.should_receive(:reregister).and_return(@user_mock)
    @knife.config[:file] = '/tmp/a_file'
    filehandle = StringIO.new
    File.should_receive(:open).with('/tmp/a_file', 'w').and_yield(filehandle)
    @knife.run
    filehandle.string.should == "private_key"
  end
end
