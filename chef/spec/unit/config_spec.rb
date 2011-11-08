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
  describe "config attribute writer: chef_server_url" do
    before do
      Chef::Config.chef_server_url = "https://junglist.gen.nz"
    end

    it "should set the registration url" do
      Chef::Config.registration_url.should == "https://junglist.gen.nz"
    end

    it "should set the template url" do
      Chef::Config.template_url.should == "https://junglist.gen.nz"
    end

    it "should set the remotefile url" do
      Chef::Config.remotefile_url.should == "https://junglist.gen.nz"
    end

    it "should set the search url" do
      Chef::Config.search_url.should == "https://junglist.gen.nz"
    end

    it "should set the role url" do
      Chef::Config.role_url.should == "https://junglist.gen.nz"
    end
  end

  describe "class method: manage_secret_key" do
    before do
      Chef::FileCache.stub!(:load).and_return(true)
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

      it "should not generate and store a chef server cookie id" do
        Chef::FileCache.should_not_receive(:store).with("chef_server_cookie_id", /\w{40}/).and_return(true)
        Chef::Config.manage_secret_key
      end
    end

  end

  describe "config attribute writer: log_method=" do
    describe "when given an object that responds to sync= e.g. IO" do
      it "should configure itself to use the IO as log_location" do
        Chef::Config.log_location = STDOUT
        Chef::Config.log_location.should == STDOUT
      end
    end

    describe "when given an object that is stringable (to_str)" do
      before do
        @mockfile = mock("File", :path => "/var/log/chef/client.log", :sync= => true)
        File.should_receive(:new).
          with("/var/log/chef/client.log", "a").
          and_return(@mockfile)
      end

      it "should configure itself to use a File object based upon the String" do
        Chef::Config.log_location = "/var/log/chef/client.log"
        Chef::Config.log_location.path.should == "/var/log/chef/client.log"
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

  describe "default values" do
    it "Chef::Config[:file_backup_path] defaults to /var/chef/backup" do
      Chef::Config[:file_backup_path].should == "/var/chef/backup"
    end

    it "Chef::Config[:ssl_verify_mode] defaults to :verify_none" do
      Chef::Config[:ssl_verify_mode].should == :verify_none
    end

    it "Chef::Config[:ssl_ca_path] defaults to nil" do
      Chef::Config[:ssl_ca_path].should be_nil
    end

    it "Chef::Config[:ssl_ca_file] defaults to nil" do
      Chef::Config[:ssl_ca_file].should be_nil
    end
  end
end
