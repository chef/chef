#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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
require 'chef/mixin/checksum'
require 'stringio'

class Chef::CMCCheck
  include Chef::Mixin::Checksum
end

describe Chef::Mixin::Checksum do
  before(:each) do
    @checksum_user = Chef::CMCCheck.new
    @cache = Chef::Digester.instance
    @file = CHEF_SPEC_DATA + "/checksum/random.txt"
    @stat = mock("File::Stat", { :mtime => Time.at(0) })
    File.stub!(:stat).and_return(@stat)
  end

  it "gets the checksum of a file" do
    @checksum_user.checksum(@file).should == "dc6665c18676f5f30fdaa420343960edf1883790f83f51f437dbfa0ff678499d"
  end

end

