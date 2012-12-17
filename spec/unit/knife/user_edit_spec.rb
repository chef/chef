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

describe Chef::Knife::UserEdit do
  before(:each) do
    Chef::Knife::UserEdit.load_deps
    @knife = Chef::Knife::UserEdit.new
    @knife.name_args = [ 'my_user' ]
    @knife.config[:disable_editing] = true
  end

  it 'loads and edits the user' do
    data = { :name => "my_user" }
    Chef::User.stub(:load).with("my_user").and_return(data)
    @knife.should_receive(:edit_data).with(data).and_return(data)
    @knife.run
  end

  it 'prints usage and exits when a user name is not provided' do
    @knife.name_args = []
    @knife.should_receive(:show_usage)
    @knife.ui.should_receive(:fatal)
    lambda { @knife.run }.should raise_error(SystemExit)
  end
end
