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
require 'chef/util/path_helper'

describe Chef::Config do
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
    it "has an empty list of formatters by default" do
      Chef::Config.formatters.should == []
    end

    it "configures a formatter with a short name" do
      Chef::Config.add_formatter(:doc)
      Chef::Config.formatters.should == [[:doc, nil]]
    end

    it "configures a formatter with a file output" do
      Chef::Config.add_formatter(:doc, "/var/log/formatter.log")
      Chef::Config.formatters.should == [[:doc, "/var/log/formatter.log"]]
    end

  end

  describe "class method: manage_secret_key" do
    before do
      Chef::FileCache.stub(:load).and_return(true)
      Chef::FileCache.stub(:has_key?).with("chef_server_cookie_id").and_return(false)
    end

    it "should generate and store a chef server cookie id" do
      Chef::FileCache.should_receive(:store).with("chef_server_cookie_id", /\w{40}/).and_return(true)
      Chef::Config.manage_secret_key
    end

    describe "when the filecache has a chef server cookie id key" do
      before do
        Chef::FileCache.stub(:has_key?).with("chef_server_cookie_id").and_return(true)
      end

      it "should not generate and store a chef server cookie id" do
        Chef::FileCache.should_not_receive(:store).with("chef_server_cookie_id", /\w{40}/)
        Chef::Config.manage_secret_key
      end
    end

  end

  [ false, true ].each do |is_windows|

    context "On #{is_windows ? 'Windows' : 'Unix'}" do
      def to_platform(*args)
        Chef::Config.platform_specific_path(*args)
      end

      before :each do
        Chef::Platform.stub(:windows?).and_return(is_windows)
      end

      describe "class method: platform_specific_path" do
        if is_windows
          it "should return a windows path on windows systems" do
            path = "/etc/chef/cookbooks"
            Chef::Config.stub(:env).and_return({ 'SYSTEMDRIVE' => 'C:' })
            # match on a regex that looks for the base path with an optional
            # system drive at the beginning (c:)
            # system drive is not hardcoded b/c it can change and b/c it is not present on linux systems
            Chef::Config.platform_specific_path(path).should == "C:\\chef\\cookbooks"
          end
        else
          it "should return given path on non-windows systems" do
            path = "/etc/chef/cookbooks"
            Chef::Config.platform_specific_path(path).should == "/etc/chef/cookbooks"
          end
        end
      end

      describe "default values" do
        let :primary_cache_path do
          if is_windows
            "#{Chef::Config.env['SYSTEMDRIVE']}\\chef"
          else
            "/var/chef"
          end
        end

        let :secondary_cache_path do
          if is_windows
            "#{Chef::Config[:user_home]}\\.chef"
          else
            "#{Chef::Config[:user_home]}/.chef"
          end
        end

        before do
          if is_windows
            Chef::Config.stub(:env).and_return({ 'SYSTEMDRIVE' => 'C:' })
            Chef::Config[:user_home] = 'C:\Users\charlie'
          else
            Chef::Config[:user_home] = '/Users/charlie'
          end

          Chef::Config.stub(:path_accessible?).and_return(false)
        end

        describe "Chef::Config[:cache_path]" do
          context "when /var/chef exists and is accessible" do
            it "defaults to /var/chef" do
              Chef::Config.stub(:path_accessible?).with(to_platform("/var/chef")).and_return(true)
              Chef::Config[:cache_path].should == primary_cache_path
            end
          end

          context "when /var/chef does not exist and /var is accessible" do
            it "defaults to /var/chef" do
              File.stub(:exists?).with(to_platform("/var/chef")).and_return(false)
              Chef::Config.stub(:path_accessible?).with(to_platform("/var")).and_return(true)
              Chef::Config[:cache_path].should == primary_cache_path
            end
          end

          context "when /var/chef does not exist and /var is not accessible" do
            it "defaults to $HOME/.chef" do
              File.stub(:exists?).with(to_platform("/var/chef")).and_return(false)
              Chef::Config.stub(:path_accessible?).with(to_platform("/var")).and_return(false)
              Chef::Config[:cache_path].should == secondary_cache_path
            end
          end

          context "when /var/chef exists and is not accessible" do
            it "defaults to $HOME/.chef" do
              File.stub(:exists?).with(to_platform("/var/chef")).and_return(true)
              File.stub(:readable?).with(to_platform("/var/chef")).and_return(true)
              File.stub(:writable?).with(to_platform("/var/chef")).and_return(false)

              Chef::Config[:cache_path].should == secondary_cache_path
            end
          end

          context "when chef is running in local mode" do
            before do
              Chef::Config.local_mode = true
            end

            context "and config_dir is /a/b/c" do
              before do
                Chef::Config.config_dir to_platform('/a/b/c')
              end

              it "cache_path is /a/b/c/local-mode-cache" do
                Chef::Config.cache_path.should == to_platform('/a/b/c/local-mode-cache')
              end
            end

            context "and config_dir is /a/b/c/" do
              before do
                Chef::Config.config_dir to_platform('/a/b/c/')
              end

              it "cache_path is /a/b/c/local-mode-cache" do
                Chef::Config.cache_path.should == to_platform('/a/b/c/local-mode-cache')
              end
            end
          end
        end

        it "Chef::Config[:file_backup_path] defaults to /var/chef/backup" do
          Chef::Config.stub(:cache_path).and_return(primary_cache_path)
          backup_path = is_windows ? "#{primary_cache_path}\\backup" : "#{primary_cache_path}/backup"
          Chef::Config[:file_backup_path].should == backup_path
        end

        it "Chef::Config[:ssl_verify_mode] defaults to :verify_peer" do
          Chef::Config[:ssl_verify_mode].should == :verify_peer
        end

        it "Chef::Config[:ssl_ca_path] defaults to nil" do
          Chef::Config[:ssl_ca_path].should be_nil
        end

        # TODO can this be removed?
        if !is_windows
          it "Chef::Config[:ssl_ca_file] defaults to nil" do
            Chef::Config[:ssl_ca_file].should be_nil
          end
        end

        it "Chef::Config[:data_bag_path] defaults to /var/chef/data_bags" do
          Chef::Config.stub(:cache_path).and_return(primary_cache_path)
          data_bag_path = is_windows ? "#{primary_cache_path}\\data_bags" : "#{primary_cache_path}/data_bags"
          Chef::Config[:data_bag_path].should == data_bag_path
        end

        it "Chef::Config[:environment_path] defaults to /var/chef/environments" do
          Chef::Config.stub(:cache_path).and_return(primary_cache_path)
          environment_path = is_windows ? "#{primary_cache_path}\\environments" : "#{primary_cache_path}/environments"
          Chef::Config[:environment_path].should == environment_path
        end

        describe "setting the config dir" do

          context "when the config file is /etc/chef/client.rb" do

            before do
              Chef::Config.config_file = to_platform("/etc/chef/client.rb")
            end

            it "config_dir is /etc/chef" do
              Chef::Config.config_dir.should == to_platform("/etc/chef")
            end

            context "and chef is running in local mode" do
              before do
                Chef::Config.local_mode = true
              end

              it "config_dir is /etc/chef" do
                Chef::Config.config_dir.should == to_platform("/etc/chef")
              end
            end

            context "when config_dir is set to /other/config/dir/" do
              before do
                Chef::Config.config_dir = to_platform("/other/config/dir/")
              end

              it "yields the explicit value" do
                Chef::Config.config_dir.should == to_platform("/other/config/dir/")
              end
            end

          end

          context "when the user's home dir is /home/charlie/" do
            before do
              Chef::Config.user_home = to_platform("/home/charlie")
            end

            it "config_dir is /home/charlie/.chef/" do
              Chef::Config.config_dir.should == Chef::Util::PathHelper.join(to_platform("/home/charlie/.chef"), '')
            end

            context "and chef is running in local mode" do
              before do
                Chef::Config.local_mode = true
              end

              it "config_dir is /home/charlie/.chef/" do
                Chef::Config.config_dir.should == Chef::Util::PathHelper.join(to_platform("/home/charlie/.chef"), '')
              end
            end
          end

        end

        if is_windows
          describe "finding the windows embedded dir" do
            let(:default_config_location) { "c:/opscode/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-11.6.0/lib/chef/config.rb" }
            let(:alternate_install_location) { "c:/my/alternate/install/place/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-11.6.0/lib/chef/config.rb" }
            let(:non_omnibus_location) { "c:/my/dev/stuff/lib/ruby/gems/1.9.1/gems/chef-11.6.0/lib/chef/config.rb" }

            let(:default_ca_file) { "c:/opscode/chef/embedded/ssl/certs/cacert.pem" }

            it "finds the embedded dir in the default location" do
              Chef::Config.stub(:_this_file).and_return(default_config_location)
              Chef::Config.embedded_dir.should == "c:/opscode/chef/embedded"
            end

            it "finds the embedded dir in a custom install location" do
              Chef::Config.stub(:_this_file).and_return(alternate_install_location)
              Chef::Config.embedded_dir.should == "c:/my/alternate/install/place/chef/embedded"
            end

            it "doesn't error when not in an omnibus install" do
              Chef::Config.stub(:_this_file).and_return(non_omnibus_location)
              Chef::Config.embedded_dir.should be_nil
            end

            it "sets the ssl_ca_cert path if the cert file is available" do
              Chef::Config.stub(:_this_file).and_return(default_config_location)
              File.stub(:exist?).with(default_ca_file).and_return(true)
              Chef::Config.ssl_ca_file.should == default_ca_file
            end
          end
        end
      end

      describe "Chef::Config[:user_home]" do
        it "should set when HOME is provided" do
          expected = to_platform("/home/kitten")
          Chef::Config.stub(:env).and_return({ 'HOME' => expected })
          Chef::Config[:user_home].should == expected
        end

        it "should be set when only USERPROFILE is provided" do
          expected = to_platform("/users/kitten")
          Chef::Config.stub(:env).and_return({ 'USERPROFILE' => expected })
          Chef::Config[:user_home].should == expected
        end

        it "falls back to the current working directory when HOME and USERPROFILE is not set" do
          Chef::Config.stub(:env).and_return({})
          Chef::Config[:user_home].should == Dir.pwd
        end
      end

      describe "Chef::Config[:encrypted_data_bag_secret]" do
        let(:db_secret_default_path){ to_platform("/etc/chef/encrypted_data_bag_secret") }

        before do
          File.stub(:exist?).with(db_secret_default_path).and_return(secret_exists)
        end

        context "/etc/chef/encrypted_data_bag_secret exists" do
          let(:secret_exists) { true }
          it "sets the value to /etc/chef/encrypted_data_bag_secret" do
            Chef::Config[:encrypted_data_bag_secret].should eq db_secret_default_path
          end
        end

        context "/etc/chef/encrypted_data_bag_secret does not exist" do
          let(:secret_exists) { false }
          it "sets the value to nil" do
            Chef::Config[:encrypted_data_bag_secret].should be_nil
          end
        end
      end

      describe "Chef::Config[:event_handlers]" do
        it "sets a event_handlers to an empty array by default" do
          Chef::Config[:event_handlers].should eq([])
        end
        it "should be able to add custom handlers" do
          o = Object.new
          Chef::Config[:event_handlers] << o
          Chef::Config[:event_handlers].should be_include(o)
        end
      end

      describe "Chef::Config[:user_valid_regex]" do
        context "on a platform that is not Windows" do
          it "allows one letter usernames" do
            any_match = Chef::Config[:user_valid_regex].any? { |regex| regex.match('a') }
            expect(any_match).to be_true
          end
        end
      end

      describe "Chef::Config[:internal_locale]" do
        let(:shell_out) do
          double("Chef::Mixin::ShellOut double", :exitstatus => 0, :stdout => locales)
        end

        let(:locales) { locale_array.join("\n") }

        before do
          allow(Chef::Config).to receive(:shell_out_with_systems_locale!).with("locale -a").and_return(shell_out)
        end

        shared_examples_for "a suitable locale" do
          it "returns an English UTF-8 locale" do
            expect(Chef::Log).to_not receive(:warn).with(/Please install an English UTF-8 locale for Chef to use/)
            expect(Chef::Log).to_not receive(:debug).with(/Defaulting to locale en_US.UTF-8 on Windows/)
            expect(Chef::Log).to_not receive(:debug).with(/No usable locale -a command found/)
            expect(Chef::Config.guess_internal_locale).to eq expected_locale
          end
        end

        context "when the result includes 'C.UTF-8'" do
          include_examples "a suitable locale" do
            let(:locale_array) { [expected_locale, "en_US.UTF-8"] }
            let(:expected_locale) { "C.UTF-8" }
          end
        end

        context "when the result includes 'en_US.UTF-8'" do
          include_examples "a suitable locale" do
            let(:locale_array) { ["en_CA.UTF-8", expected_locale, "en_NZ.UTF-8"] }
            let(:expected_locale) { "en_US.UTF-8" }
          end
        end

        context "when the result includes 'en_US.utf8'" do
          include_examples "a suitable locale" do
            let(:locale_array) { ["en_CA.utf8", "en_US.utf8", "en_NZ.utf8"] }
            let(:expected_locale) { "en_US.UTF-8" }
          end
        end

        context "when the result includes 'en.UTF-8'" do
          include_examples "a suitable locale" do
            let(:locale_array) { ["en.ISO8859-1", expected_locale] }
            let(:expected_locale) { "en.UTF-8" }
          end
        end

        context "when the result includes 'en_*.UTF-8'" do
          include_examples "a suitable locale" do
            let(:locale_array) { [expected_locale, "en_CA.UTF-8", "en_GB.UTF-8"] }
            let(:expected_locale) { "en_AU.UTF-8" }
          end
        end

        context "when the result includes 'en_*.utf8'" do
          include_examples "a suitable locale" do
            let(:locale_array) { ["en_AU.utf8", "en_CA.utf8", "en_GB.utf8"] }
            let(:expected_locale) { "en_AU.UTF-8" }
          end
        end

        context "when the result does not include 'en_*.UTF-8'" do
          let(:locale_array) { ["af_ZA", "af_ZA.ISO8859-1", "af_ZA.ISO8859-15", "af_ZA.UTF-8"] }

          it "should fall back to C locale" do
            expect(Chef::Log).to receive(:warn).with("Please install an English UTF-8 locale for Chef to use, falling back to C locale and disabling UTF-8 support.")
            expect(Chef::Config.guess_internal_locale).to eq 'C'
          end
        end

        context "on error" do
          let(:locale_array) { [] }

          before do
            allow(Chef::Config).to receive(:shell_out_with_systems_locale!).and_raise("THIS IS AN ERROR")
          end

          it "should default to 'en_US.UTF-8'" do
            if is_windows
              expect(Chef::Log).to receive(:debug).with("Defaulting to locale en_US.UTF-8 on Windows, until it matters that we do something else.")
            else
              expect(Chef::Log).to receive(:debug).with("No usable locale -a command found, assuming you have en_US.UTF-8 installed.")
            end
            expect(Chef::Config.guess_internal_locale).to eq "en_US.UTF-8"
          end
        end
      end
    end
  end
end
