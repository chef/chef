#
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright:: Copyright (c) 2013 Lamont Granquist
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

describe Chef::Provider::RemoteFile::HTTP do

  before(:each) do
    @uri = URI.parse("http://opscode.com/seattle.txt")
  end

  describe "when contructing the object" do
    before do
      @new_resource = mock('Chef::Resource::RemoteFile (new_resource)')
      @current_resource = mock('Chef::Resource::RemoteFile (current_resource)')
    end

    describe "when the current resource has no source" do
      before do
        @current_resource.should_receive(:source).and_return(nil)
      end

      it "stores the uri it is passed" do
        fetcher = Chef::Provider::RemoteFile::HTTP.new(@uri, @new_resource, @current_resource)
        fetcher.uri.should == @uri
      end

    end

    describe "when the current resource has a source" do
    end
  end

  describe "when fetching the uri" do
  end

end

