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

describe Chef::Knife::UserShow do
  before(:each) do
    Chef::Knife::UserShow.load_deps
    @knife = Chef::Knife::UserShow.new
    @knife.name_args = [ 'my_user' ]
    @user_mock = mock('user_mock')
  end

  it 'loads and displays the user' do
    Chef::User.should_receive(:load).with('my_user').and_return(@user_mock)
    @knife.should_receive(:format_for_display).with(@user_mock)
    @knife.run
  end

  it 'prints usage and exits when a user name is not provided' do
    @knife.name_args = []
    @knife.should_receive(:show_usage)
    @knife.ui.should_receive(:fatal)
    lambda { @knife.run }.should raise_error(SystemExit)
  end
end
