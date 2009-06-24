#
# Author:: Adam Jacob (<adam@opscode.com>)
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

describe Chef::Config do
  describe "class method: manage_secret_key" do
    before do
      Chef::FileCache.stub!(:has_key?).with("chef_server_cookie_id").and_return(false)
    end
    
    it "should generate and store a chef server cookie id" do
      Chef::FileCache.should_receive(:store).with("chef_server_cookie_id", /\w{40}/).and_return(true)
      Chef::Config.manage_secret_key
    end
    
    describe "when the filecache has a chef server cookie id key" do
      before do
        Chef::FileCache.stub!(:has_key?).with("chef_server_cookie_id").and_return(true)        
      end
    end
    
  end
  
  describe "class method: log_method=" do
    describe "when given an object that responds to sync e.g. IO" do
      it "should internally configure itself to use the IO as log_location" do
        Chef::Config.should_receive(:configure).and_return(STDOUT)
        Chef::Config.log_location = STDOUT
      end
    end
    
    describe "when not given an object that responds to sync e.g. String" do
      it "should internally configure itself to use a File object based upon the String" do
        File.should_receive(:new).with("/var/log/chef/client.log", "w+")
        Chef::Config.log_location = "/var/log/chef/client.log"
      end
    end
  end
  
  describe "class method: openid_providers=" do   
    it "should not log an appropriate deprecation info message" do
      Chef::Log.should_not_receive(:info).with("DEPRECATION: openid_providers will be removed, please use authorized_openid_providers").and_return(true)
      Chef::Config.openid_providers = %w{opscode.com junglist.gen.nz}
    end 
    
    it "should internally configure authorized_openid_providers with the value given" do
      Chef::Config.should_receive(:configure).and_return(%w{opscode.com junglist.gen.nz})
      Chef::Config.openid_providers = %w{opscode.com junglist.gen.nz}
    end
  end
end
