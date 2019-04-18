#
# Author:: AJ Christensen (<aj@junglist.gen.nz>)
# Author:: Mark Mzyk (mmzyk@chef.io)
# Copyright:: Copyright 2008-2018, Chef Software Inc.
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

require "spec_helper"

describe Chef::Application do
  before do
    @original_argv = ARGV.dup
    ARGV.clear
    Chef::Log.logger = Logger.new(StringIO.new)
    @app = Chef::Application.new
    allow(@app).to receive(:trap)
    allow(Dir).to receive(:chdir).and_return(0)
    allow(@app).to receive(:reconfigure)
    Chef::Log.init(STDERR)
  end

  after do
    ARGV.replace(@original_argv)
  end

  context "when there are no configuration errors" do

    before do
      expect(Chef::Log).to_not receive(:fatal)
      expect(Chef::Application).to_not receive(:fatal!)
    end

    describe "reconfigure" do
      before do
        @app = Chef::Application.new
        allow(@app).to receive(:configure_chef).and_return(true)
        allow(@app).to receive(:configure_logging).and_return(true)
      end

      it "should configure chef" do
        expect(@app).to receive(:configure_chef).and_return(true)
        @app.reconfigure
      end

      it "should configure logging" do
        expect(@app).to receive(:configure_logging).and_return(true)
        @app.reconfigure
      end

      it "should not receive set_specific_recipes" do
        expect(@app).to_not receive(:set_specific_recipes)
        @app.reconfigure
      end
    end

    describe Chef::Application do
      before do
        @app = Chef::Application.new
      end

      describe "run" do
        before do
          allow(@app).to receive(:setup_application).and_return(true)
          allow(@app).to receive(:run_application).and_return(true)
          allow(@app).to receive(:configure_chef).and_return(true)
          allow(@app).to receive(:configure_logging).and_return(true)
        end

        it "should reconfigure the application before running" do
          expect(@app).to receive(:reconfigure).and_return(true)
          @app.run
        end

        it "should setup the application before running it" do
          expect(@app).to receive(:setup_application).and_return(true)
          @app.run
        end

        describe "when enforce_license is set to true" do
          it "should check the license acceptance" do
            expect(@app).to receive(:check_license_acceptance)
            @app.run(true)
          end
        end

        it "should run the actual application" do
          expect(@app).to receive(:run_application).and_return(true)
          @app.run
        end
      end
    end

    describe "configure_chef" do
      before do
        # Silence warnings when no config file exists
        allow(Chef::Log).to receive(:warn)

        @app = Chef::Application.new
        allow(@app).to receive(:parse_options).and_return(true)
        allow(::File).to receive(:read).with("/proc/sys/crypto/fips_enabled").and_call_original
        expect(Chef::Config).to receive(:export_proxies).and_return(true)
      end

      it "should parse the commandline options" do
        expect(@app).to receive(:parse_options).and_return(true)
        @app.config[:config_file] = "/etc/chef/default.rb" # have a config file set, to prevent triggering error block
        @app.configure_chef
      end

      describe "when a config_file is present" do
        let(:config_content) { "rspec_ran('true')" }
        let(:config_location) { "/etc/chef/default.rb" }

        let(:config_location_pathname) do
          p = Pathname.new(config_location)
          allow(p).to receive(:realpath).and_return(config_location)
          p
        end

        before do
          @app.config[:config_file] = config_location

          # force let binding to get evaluated or else we stub Pathname.new before we try to use it.
          config_location_pathname
          allow(Pathname).to receive(:new).with(config_location).and_return(config_location_pathname)
          expect(File).to receive(:read)
            .with(config_location)
            .and_return(config_content)
        end

        it "should configure chef::config from a file" do
          expect(Chef::Config).to receive(:from_string).with(config_content, File.expand_path(config_location))
          @app.configure_chef
        end

        it "should merge the local config hash into chef::config" do
          # File.should_receive(:open).with("/etc/chef/default.rb").and_yield(@config_file)
          @app.configure_chef
          expect(Chef::Config.rspec_ran).to eq("true")
        end

        context "when openssl fips" do
          before do
            allow(Chef::Config).to receive(:fips).and_return(true)
          end

          it "sets openssl in fips mode" do
            expect(Chef::Config).to receive(:enable_fips_mode)
            @app.configure_chef
          end
        end
      end

      describe "when there is no config_file defined" do
        before do
          @app.config[:config_file] = nil
        end

        it "should emit a warning" do
          expect(Chef::Config).not_to receive(:from_file).with("/etc/chef/default.rb")
          expect(Chef::Log).to receive(:warn).with("No config file found or specified on command line. Using command line options instead.")
          @app.configure_chef
        end
      end

      describe "when the config file is set and not found" do
        before do
          @app.config[:config_file] = "/etc/chef/notfound"
        end
        it "should use the passed in command line options and defaults" do
          expect(Chef::Config).to receive(:merge!).at_least(:once)
          @app.configure_chef
        end
      end
    end

    describe "when configuring the logger" do
      before do
        @app = Chef::Application.new
        allow(Chef::Log).to receive(:init)
      end

      it "should initialise the chef logger" do
        allow(Chef::Log).to receive(:level=)
        @monologger = double("Monologger")
        expect(MonoLogger).to receive(:new).with(Chef::Config[:log_location]).and_return(@monologger)
        allow(MonoLogger).to receive(:new).with(STDOUT).and_return(@monologger)
        allow(@monologger).to receive(:formatter=).with(Chef::Log.logger.formatter)
        expect(Chef::Log).to receive(:init).with(@monologger)
        @app.configure_logging
      end

      shared_examples_for "log_level_is_auto" do
        before do
          allow(STDOUT).to receive(:tty?).and_return(true)
        end

        it "configures the log level to :warn" do
          @app.configure_logging
          expect(Chef::Log.level).to eq(:warn)
        end

        context "when force_formater is configured" do
          before do
            Chef::Config[:force_formatter] = true
          end

          it "configures the log level to warn" do
            @app.configure_logging
            expect(Chef::Log.level).to eq(:warn)
          end
        end

        context "when force_logger is configured" do
          before do
            Chef::Config[:force_logger] = true
          end

          it "configures the log level to info" do
            @app.configure_logging
            expect(Chef::Log.level).to eq(:info)
          end
        end

        context "when both are is configured" do
          before do
            Chef::Config[:force_logger] = true
            Chef::Config[:force_formatter] = true
          end

          it "configures the log level to warn" do
            @app.configure_logging
            expect(Chef::Log.level).to eq(:warn)
          end
        end

      end

      context "when log_level is not set" do
        it_behaves_like "log_level_is_auto"
      end

      context "when log_level is :auto" do
        before do
          Chef::Config[:log_level] = :auto
        end

        it_behaves_like "log_level_is_auto"
      end

      describe "log_location" do
        shared_examples("sets log_location") do |config_value, expected_class|
          context "when the configured value is #{config_value.inspect}" do
            let(:logger_instance) { instance_double(expected_class).as_null_object }

            before do
              allow(expected_class).to receive(:new).and_return(logger_instance)
              Chef::Config[:log_location] = config_value
            end

            it "it sets log_location to an instance of #{expected_class}" do
              expect(expected_class).to receive(:new).with no_args
              @app.configure_logging
              expect(Chef::Config[:log_location]).to be logger_instance
            end
          end
        end

        if Chef::Platform.windows?
          it_behaves_like "sets log_location", :win_evt, Chef::Log::WinEvt
          it_behaves_like "sets log_location", "win_evt", Chef::Log::WinEvt
        else
          it_behaves_like "sets log_location", :syslog, Chef::Log::Syslog
          it_behaves_like "sets log_location", "syslog", Chef::Log::Syslog
        end
      end
    end
  end

  context "with an invalid log location" do

    it "logs a fatal error and exits" do
      Chef::Config[:log_location] = "/tmp/non-existing-dir/logfile"
      expect(Chef::Log).to receive(:fatal).at_least(:once)
      expect(Process).to receive(:exit)
      @app.configure_logging
    end
  end

  describe "class method: fatal!" do
    before do
      allow(STDERR).to receive(:puts).with("FATAL: blah").and_return(true)
      allow(Chef::Log).to receive(:fatal).and_return(true)
      allow(Process).to receive(:exit).and_return(true)
    end

    it "should log an error message to the logger" do
      expect(Chef::Log).to receive(:fatal).with("blah").and_return(true)
      Chef::Application.fatal! "blah"
    end

    describe "when a standard exit code is supplied" do
      it "should exit with the given exit code" do
        expect(Process).to receive(:exit).with(41).and_return(true)
        Chef::Application.fatal! "blah", 41
      end
    end

    describe "when a non-standard exit code is supplied" do
      it "should exit with the default exit code" do
        expect(Process).to receive(:exit).with(1).and_return(true)
        Chef::Application.fatal! "blah", -100
      end
    end

    describe "when an exit code is not supplied" do
      it "should exit with the default exit code" do
        expect(Process).to receive(:exit).with(1).and_return(true)
        Chef::Application.fatal! "blah"
      end
    end

  end

  describe "setup_application" do
    before do
      @app = Chef::Application.new
    end

    it "should raise an error" do
      expect { @app.setup_application }.to raise_error(Chef::Exceptions::Application)
    end
  end

  describe "run_application" do
    before do
      @app = Chef::Application.new
    end

    it "should raise an error" do
      expect { @app.run_application }.to raise_error(Chef::Exceptions::Application)
    end
  end

  context "when the config file is not available" do
    it "should warn for bad config file path" do
      @app.config[:config_file] = "/tmp/non-existing-dir/file"
      config_file_regexp = Regexp.new @app.config[:config_file]
      expect(Chef::Log).to receive(:warn).at_least(:once).with(config_file_regexp).and_return(true)
      allow(Chef::Log).to receive(:warn).and_return(true)
      @app.configure_chef
    end
  end

  describe "run_chef_client" do
    context "with an application" do
      let(:app) { Chef::Application.new }

      context "when called with an invalid argument" do
        before do
          allow(app).to receive(:fork_chef_client).and_return(true)
          allow(app).to receive(:run_with_graceful_exit_option).and_return(true)
        end

        it "should raise an argument error detailing the problem" do
          specific_recipes_regexp = Regexp.new "received non-Array like specific_recipes argument"
          expect { app.run_chef_client(nil) }.to raise_error(ArgumentError, specific_recipes_regexp)
        end
      end

      context "when called with an Array-like argument (#size)" do
        before do
          allow(app).to receive(:fork_chef_client).and_return(true)
          allow(app).to receive(:run_with_graceful_exit_option).and_return(true)
        end

        it "should be cool" do
          expect { app.run_chef_client([]) }.not_to raise_error
        end
      end
    end

  end

  describe "configuration errors" do
    before do
      expect(Process).to receive(:exit)
    end

    def raises_informative_fatals_on_configure_chef
      config_file_regexp = Regexp.new @app.config[:config_file]
      expect(Chef::Log).to receive(:fatal)
        .with(/Configuration error/)
      expect(Chef::Log).to receive(:fatal)
        .with(config_file_regexp)
        .at_least(1).times
      @app.configure_chef
    end

    describe "when config file exists but contains errors" do
      def create_config_file(text)
        @config_file = Tempfile.new("rspec-chef-config")
        @config_file.write(text)
        @config_file.close
        @app.config[:config_file] = @config_file.path
      end

      after(:each) do
        @config_file.unlink
      end

      it "should raise informative fatals for badly written config" do
        create_config_file("text that should break the config parsing")
        raises_informative_fatals_on_configure_chef
      end
    end
  end

  describe "merged config" do
    class MyTestConfig < Chef::Config
      extend Mixlib::Config

      default :test_config_1, "config default"
      default :test_config_2, "config default"
    end

    class MyAppClass < Chef::Application
      # there's an implicit test here that mixlib-cli's separate_default_options is being inherited
      option :test_config_2, long: "--test-config2 CONFIG", default: "cli default"
    end

    before(:each) do
      MyTestConfig.reset
      @original_argv = ARGV.dup
      ARGV.clear
      @app = MyAppClass.new
      expect(@app).to receive(:chef_config).at_least(:once).and_return(MyTestConfig)
      expect(Chef::ConfigFetcher).to receive(:new).and_return(fake_config_fetcher)
      allow(@app).to receive(:log).and_return(instance_double(Mixlib::Log, warn: nil)) # ignorken
    end

    after(:each) do
      ARGV.replace(@original_argv)
    end

    let(:fake_config_fetcher) { instance_double(Chef::ConfigFetcher, expanded_path: "/thisbetternotexist", "config_missing?": false, read_config: "" ) }

    it "reading a mixlib-config default works" do
      @app.parse_options
      @app.load_config_file
      expect(MyTestConfig[:test_config_1]).to eql("config default")
    end

    it "a mixlib-cli default overrides a mixlib-config default" do
      @app.parse_options
      @app.load_config_file
      expect(MyTestConfig[:test_config_2]).to eql("cli default")
    end

    it "a set mixlib-config value overrides a mixlib-config default" do
      expect(fake_config_fetcher).to receive(:read_config).and_return(%q{test_config_1 "config setting"})
      @app.parse_options
      @app.load_config_file
      expect(MyTestConfig[:test_config_1]).to eql("config setting")
    end

    it "a set mixlib-config value overrides a mixlib-cli default" do
      expect(fake_config_fetcher).to receive(:read_config).and_return(%q{test_config_2 "config setting"})
      @app.parse_options
      @app.load_config_file
      expect(MyTestConfig[:test_config_2]).to eql("config setting")
    end

    it "a set mixlib-cli value overrides everything else" do
      expect(fake_config_fetcher).to receive(:read_config).and_return(%q{test_config_2 "config setting"})
      ARGV.replace("--test-config2 cli-setting".split)
      @app.parse_options
      @app.load_config_file
      expect(MyTestConfig[:test_config_2]).to eql("cli-setting")
    end
  end
end
