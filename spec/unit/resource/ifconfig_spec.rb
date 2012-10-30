#
# Author:: Tyler Cloke (<tyler@opscode.com>)
# Copyright:: Copyright (c) 2009 Joe Williams
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

describe Chef::Resource::Ifconfig do

  before(:each) do
    @resource = Chef::Resource::Ifconfig.new("fakey_fakerton")
  end

  describe "when it has target, hardware address, inet address, and a mask" do
    before do 
      @resource.device("charmander")
      @resource.target("team_rocket")
      @resource.hwaddr("11.2223.223")
      @resource.inet_addr("434.2343.23")
      @resource.mask("255.255.545")
    end

    it "describes its state" do
      state = @resource.state
      state[:inet_addr].should == "434.2343.23"
      state[:mask].should == "255.255.545"
    end

    it "returns the device as its identity" do
      @resource.identity.should == "charmander"
    end
  end
end
