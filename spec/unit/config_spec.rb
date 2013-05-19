#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Kyle Goodwin (<kgoodwin@primerevenue.com>)
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
require 'chef/exceptions'

describe Chef::Config do
  before(:all) do
    @original_config = Chef::Config.hash_dup
    @original_env = { 'HOME' => ENV['HOME'], 'SYSTEMDRIVE' => ENV['SYSTEMDRIVE'], 'HOMEPATH' => ENV['HOMEPATH'], 'USERPROFILE' => ENV['USERPROFILE'] }
  end

  describe "config attribute writer: chef_server_url" do
    before do
      Chef::Config.chef_server_url = "https://junglist.gen.nz"
    end

    it "sets the server url" do
      Chef::Config.chef_server_url.should == "https://junglist.gen.nz"
    end

    context "when the url has a leading space" do
      before do
        Chef::Config.chef_server_url = " https://junglist.gen.nz"
      end

      it "strips the space from the url when setting" do
        Chef::Config.chef_server_url.should == "https://junglist.gen.nz"
      end

    end

    context "when the url is a frozen string" do
      before do
        Chef::Config.chef_server_url = " https://junglist.gen.nz".freeze
      end

      it "strips the space from the url when setting without raising an error" do
        Chef::Config.chef_server_url.should == "https://junglist.gen.nz"
      end
    end

  end

  describe "when configuring formatters" do
      # if TTY and not(force-logger)
      #   formatter = configured formatter or default formatter
      #   formatter goes to STDOUT/ERR
      #   if log file is writeable
      #     log level is configured level or info
      #     log location is file
      #   else
      #     log level is warn
      #     log location is STDERR
      #    end
      # elsif not(TTY) and force formatter
      #   formatter = configured formatter or default formatter
      #   if log_location specified
      #     formatter goes to log_location
      #   else
      #     formatter goes to STDOUT/ERR
      #   end
      # else
      #   formatter = "null"
      #   log_location = configured-value or defualt
      #   log_level = info or defualt
      # end
      #
    before do
      @config_class = Class.new(Chef::Config)
    end

    it "has an empty list of formatters by default" do
      @config_class.formatters.should == []
    end

    it "configures a formatter with a short name" do
      @config_class.add_formatter(:doc)
      @config_class.formatters.should == [[:doc, nil]]
    end

    it "configures a formatter with a file output" do
      @config_class.add_formatter(:doc, "/var/log/formatter.log")
      @config_class.formatters.should == [[:doc, "/var/log/formatter.log"]]
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
        Chef::FileCache.should_not_receive(:store).with("chef_server_cookie_id", /\w{40}/)
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

      after do
        Chef::Config.log_location = STDOUT
      end

      it "should configure itself to use a File object based upon the String" do
        Chef::Config.log_location = "/var/log/chef/client.log"
        Chef::Config.log_location.path.should == "/var/log/chef/client.log"
      end
    end
  end

  describe "class method: plaform_specific_path" do
    it "should return given path on non-windows systems" do
      platform_mock :unix do
        path = "/etc/chef/cookbooks"
        Chef::Config.platform_specific_path(path).should == "/etc/chef/cookbooks"
      end
    end

    it "should return a windows path on windows systems" do
      platform_mock :windows do
        path = "/etc/chef/cookbooks"
        ENV.stub!(:[]).with('SYSTEMDRIVE').and_return('C:')
        # match on a regex that looks for the base path with an optional
        # system drive at the beginning (c:)
        # system drive is not hardcoded b/c it can change and b/c it is not present on linux systems
        Chef::Config.platform_specific_path(path).should == "C:\\chef\\cookbooks"
      end
    end
  end

  describe "default values" do
    before(:each) do
      # reload Chef::Config to ensure defaults are truely active
      load File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "lib", "chef", "config.rb"))
    end

    after(:each) do
      # reload spec helper to re-set any spec specific Chef::Config values
      load File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper.rb"))
    end

    it "Chef::Config[:file_backup_path] defaults to /var/chef/backup" do
      backup_path = if windows?
        "#{ENV['SYSTEMDRIVE']}\\chef\\backup"
      else
        "/var/chef/backup"
      end
      Chef::Config[:file_backup_path].should == backup_path
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

    it "Chef::Config[:data_bag_path] defaults to /var/chef/data_bags" do
      data_bag_path =
        Chef::Config.platform_specific_path("/var/chef/data_bags")
      Chef::Config[:data_bag_path].should == data_bag_path
    end

    it "Chef::Config[:environment_path] defaults to /var/chef/environments" do
      environment_path = if windows?
        "C:\\chef\\environments"
      else
        "/var/chef/environments"
      end

      Chef::Config[:environment_path].should == environment_path
    end
  end

  describe "Chef::Config[:user_home]" do
    it "should set when HOME is provided" do
      ENV['HOME'] = "/home/kitten"
      load File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "lib", "chef", "config.rb"))
      Chef::Config[:user_home].should == "/home/kitten"
    end

    it "should be set when only USERPROFILE is provided" do
      ENV['HOME'], ENV['SYSTEMDRIVE'],  ENV['HOMEPATH'] = nil, nil, nil
      ENV['USERPROFILE'] = "/users/kitten"
      load File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "lib", "chef", "config.rb"))
      Chef::Config[:user_home].should == "/users/kitten"
    end

    after(:each) do
      @original_env.each do |env_setting|
        ENV[env_setting[0]] = env_setting[1]
      end
    end
  end

  describe "Chef::Config[:encrypted_data_bag_secret]" do
    db_secret_default_path =
      Chef::Config.platform_specific_path("/etc/chef/encrypted_data_bag_secret")

    let(:db_secret_default_path){ db_secret_default_path }

    before do
      File.stub(:exist?).with(db_secret_default_path).and_return(secret_exists)
      # ugh...the only way to properly test this since the conditional
      # is evaluated at file load/require time.
      $LOADED_FEATURES.delete_if{|f| f =~ /chef\/config\.rb/}
      require 'chef/config'
    end

    context "#{db_secret_default_path} exists" do
      let(:secret_exists) { true }
      it "sets the value to #{db_secret_default_path}" do
        Chef::Config[:encrypted_data_bag_secret].should eq db_secret_default_path
      end
    end

    context "#{db_secret_default_path} does not exist" do
      let(:secret_exists) { false }
      it "sets the value to nil" do
        Chef::Config[:encrypted_data_bag_secret].should be_nil
      end
    end
  end

  describe "Chef::Config[:log_location]" do
    it "raises ConfigurationError when log_location directory is missing" do
      missing_path = "/tmp/non-existing-dir/file"
      expect{Chef::Config.log_location = missing_path}.to raise_error Chef::Exceptions::ConfigurationError
    end
  end

  after(:each) do
    Chef::Config.configuration = @original_config
  end
end
