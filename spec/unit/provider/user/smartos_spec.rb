#
# Author:: Dave Eddy (<dave@daveeddy.com>)
# Copyright:: Copyright 2015, Dave Eddy
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

ShellCmdResult = Struct.new(:stdout, :stderr, :exitstatus)

require 'mixlib/shellout'
require 'spec_helper'

describe Chef::Provider::User::SmartOS do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::User.new('dave')
    @new_resource.comment   'Dave Eddy'
    @new_resource.uid       1000
    @new_resource.gid       1000
    @new_resource.home      '/home/dave'
    @new_resource.shell     '/bin/bash'
    @new_resource.password  'bahamas10'
    @new_resource.supports  :manage_home => true

    @current_resource = @new_resource.dup

    @provider = Chef::Provider::User::SmartOS.new(@new_resource, @run_context)
    @provider.current_resource = @current_resource
  end

  describe 'determining if the user is locked' do
    # locked shadow lines
    [
      'dave:LK:::::::',
      'dave:*LK*:::::::',
      'dave:*LK*foobar:::::::',
      'dave:*LK*bahamas10:::::::',
      'dave:*LK*L....:::::::',
    ].each do |shadow|
      it "should return true if user is locked with #{shadow}" do
        shell_return = ShellCmdResult.new(shadow + "\n", '', 0)
        expect(@provider).to receive(:shell_out!).with('getent', 'shadow', @new_resource.username).and_return(shell_return)
        expect(@provider.check_lock).to eql(true)
      end
    end

    # unlocked shadow lines
    [
      'dave:NP:::::::',
      'dave:*NP*:::::::',
      'dave:foobar:::::::',
      'dave:bahamas10:::::::',
      'dave:L...:::::::',
    ].each do |shadow|
      it "should return false if user is unlocked with #{shadow}" do
        shell_return = ShellCmdResult.new(shadow + "\n", '', 0)
        expect(@provider).to receive(:shell_out!).with('getent', 'shadow', @new_resource.username).and_return(shell_return)
        expect(@provider.check_lock).to eql(false)
      end
    end
  end

  describe 'when locking the user' do
    it 'should run passwd -l with the new resources username' do
      shell_return = ShellCmdResult.new('', '', 0)
      expect(@provider).to receive(:shell_out!).with('passwd', '-l', @new_resource.username).and_return(shell_return)
      @provider.lock_user
    end
  end

  describe 'when unlocking the user' do
    it 'should run passwd -u with the new resources username' do
      shell_return = ShellCmdResult.new('', '', 0)
      expect(@provider).to receive(:shell_out!).with('passwd', '-u', @new_resource.username).and_return(shell_return)
      @provider.unlock_user
    end
  end
end
