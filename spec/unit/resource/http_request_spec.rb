#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Tyler Cloke (<tyler@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

describe Chef::Resource::HttpRequest do

  before(:each) do
    @resource = Chef::Resource::HttpRequest.new("fakey_fakerton")
  end  

  it "should create a new Chef::Resource::HttpRequest" do
    @resource.should be_a_kind_of(Chef::Resource)
    @resource.should be_a_kind_of(Chef::Resource::HttpRequest)
  end

  it "should set url to a string" do
    @resource.url "http://slashdot.org"
    @resource.url.should eql("http://slashdot.org")
  end
  
  it "should set the message to the name by default" do
    @resource.message.should eql("fakey_fakerton")
  end
  
  it "should set message to a string" do
    @resource.message "monkeybars"
    @resource.message.should eql("monkeybars")
  end

  describe "when it has a message and headers" do
    before do 
      @resource.url("http://www.trololol.net")
      @resource.message("Get sum post brah.")
      @resource.headers({"head" => "tail"})
    end

    it "returns the url as its identity" do
      @resource.identity.should == "http://www.trololol.net"
    end
  end
  
end
