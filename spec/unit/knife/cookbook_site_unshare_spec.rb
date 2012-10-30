#
# Author:: Stephen Delano (<stephen@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

describe Chef::Knife::CookbookSiteUnshare do

  before(:each) do
    @knife = Chef::Knife::CookbookSiteUnshare.new
    @knife.name_args = ['cookbook_name']
    @knife.stub!(:confirm).and_return(true)

    @rest = mock('Chef::REST')
    @rest.stub!(:delete_rest).and_return(true)
    @knife.stub!(:rest).and_return(@rest)
    @stdout = StringIO.new
    @knife.ui.stub!(:stdout).and_return(@stdout)
  end

  describe 'run' do

    describe 'with no cookbook argument' do
      it 'should print the usage and exit' do
        @knife.name_args = []
        @knife.ui.should_receive(:fatal)
        @knife.should_receive(:show_usage)
        lambda { @knife.run }.should raise_error(SystemExit)
      end
    end

    it 'should confirm you want to unshare the cookbook' do
      @knife.should_receive(:confirm)
      @knife.run
    end

    it 'should send a delete request to the cookbook site' do
      @rest.should_receive(:delete_rest)
      @knife.run
    end

    it 'should log an error and exit when forbidden' do
      exception = mock('403 "Forbidden"', :code => '403')
      @rest.stub!(:delete_rest).and_raise(Net::HTTPServerException.new('403 "Forbidden"', exception))
      @knife.ui.should_receive(:error)
      lambda { @knife.run }.should raise_error(SystemExit)
    end

    it 'should re-raise any non-forbidden errors on delete_rest' do
      exception = mock('500 "Application Error"', :code => '500')
      @rest.stub(:delete_rest).and_raise(Net::HTTPServerException.new('500 "Application Error"', exception))
      lambda { @knife.run }.should raise_error(Net::HTTPServerException)
    end

    it 'should log a success message' do
      @knife.ui.should_receive(:info)
      @knife.run
    end

  end

end
