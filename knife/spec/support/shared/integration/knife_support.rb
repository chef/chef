#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require "chef/config"
require "chef/knife"
require "chef/application/knife"
require "logger"
require "chef/log"
require "chef/chef_fs/file_system_cache"

module KnifeSupport
  DEBUG = ENV["DEBUG"]
  def knife(*args, input: nil, instance_filter: nil)
    # Allow knife('role from file roles/blah.json') rather than requiring the
    # arguments to be split like knife('role', 'from', 'file', 'roles/blah.json')
    # If any argument will have actual spaces in it, the long form is required.
    # (Since knife commands always start with the command name, and command
    # names with spaces are always multiple args, this is safe.)
    if args.length == 1
      args = args[0].split(/\s+/)
    end

    # Make output stable
    Chef::Config[:concurrency] = 1

    # Work on machines where we can't access /var
    Dir.mktmpdir("checksums") do |checksums_cache_dir|
      Chef::Config[:syntax_check_cache_path] = checksums_cache_dir

      # This is Chef::Knife.run without load_commands--we'll load stuff
      # ourselves, thank you very much
      stdout = StringIO.new
      stderr = StringIO.new

      stdin = if input
                StringIO.new(input)
              else
                STDIN
              end

      begin
        puts "knife: #{args.join(" ")}" if DEBUG
        subcommand_class = Chef::Knife.subcommand_class_from(args)
        subcommand_class.options = Chef::Application::Knife.options.merge(subcommand_class.options)
        subcommand_class.load_deps
        instance = subcommand_class.new(args)

        # Load configs
        instance.merge_configs

        # Capture stdout/stderr
        instance.ui = Chef::Knife::UI.new(stdout, stderr, stdin, instance.config.merge(disable_editing: true))

        # Don't print stuff
        Chef::Config[:verbosity] = ( DEBUG ? 2 : 0 )
        instance.config[:config_file] = File.join(CHEF_SPEC_DATA, "null_config.rb")

        # Ensure the ChefFS cache is empty
        Chef::ChefFS::FileSystemCache.instance.reset!

        # Configure chef with a (mostly) blank knife.rb
        # We set a global and then mutate it in our stub knife.rb so we can be
        # extra sure that we're not loading someone's real knife.rb and then
        # running test scenarios against a real chef server. If things don't
        # smell right, abort.

        # To ensure that we don't pick up a user's credentials file we lie through our teeth about
        # it's existence.
        allow(File).to receive(:file?).and_call_original
        allow(File).to receive(:file?).with(File.expand_path("~/.chef/credentials")).and_return(false)

        # Set a canary that is modified by the default null_config.rb config file.
        $__KNIFE_INTEGRATION_FAILSAFE_CHECK = "ole"

        # Allow tweaking the knife instance before configuration.
        instance_filter.call(instance) if instance_filter

        instance.configure_chef

        # The canary is incorrect, meaning the normal null_config.rb didn't run. Something is wrong.
        unless $__KNIFE_INTEGRATION_FAILSAFE_CHECK == "ole ole"
          raise Exception, "Potential misconfiguration of integration tests detected. Aborting test."
        end

        logger = Logger.new(stderr)
        logger.formatter = proc { |severity, datetime, progname, msg| "#{severity}: #{msg}\n" }
        Chef::Log.use_log_devices([logger])
        Chef::Log.level = ( DEBUG ? :debug : :warn )
        Chef::Log::Formatter.show_time = false

        instance.run_with_pretty_exceptions(true)

        exit_code = 0

      # This is how rspec catches exit()
      rescue SystemExit => e
        exit_code = e.status
      ensure
        Chef::Config.delete(:syntax_check_cache_path)
        Chef::Config.delete(:concurrency)
      end

      KnifeResult.new(stdout.string, stderr.string, exit_code)
    end
  end

  class KnifeResult

    include ::RSpec::Matchers

    def initialize(stdout, stderr, exit_code)
      @stdout = stdout
      @stderr = stderr
      @exit_code = exit_code
    end

    attr_reader :stdout
    attr_reader :stderr
    attr_reader :exit_code

    def should_fail(*args)
      expected = {}
      args.each do |arg|
        if arg.is_a?(Hash)
          expected.merge!(arg)
        elsif arg.is_a?(Integer)
          expected[:exit_code] = arg
        else
          expected[:stderr] = arg
        end
      end
      expected[:exit_code] = 1 unless expected[:exit_code]
      should_result_in(expected)
    end

    def should_succeed(*args)
      expected = {}
      args.each do |arg|
        if arg.is_a?(Hash)
          expected.merge!(arg)
        else
          expected[:stdout] = arg
        end
      end
      should_result_in(expected)
    end

    private

    def should_result_in(expected)
      expected[:stdout] = "" unless expected[:stdout]
      expected[:stdout] = expected[:stdout].is_a?(String) ? expected[:stdout].gsub(/[ \t\f\v]+$/, "") : expected[:stdout]
      expected[:stderr] = "" unless expected[:stderr]
      expected[:stderr] = expected[:stderr].is_a?(String) ? expected[:stderr].gsub(/[ \t\f\v]+$/, "") : expected[:stderr]
      expected[:exit_code] = 0 unless expected[:exit_code]
      # TODO make this go away
      stderr_actual = @stderr.sub(/^WARNING: No knife configuration file found\n/, "")
      stderr_actual = stderr_actual.gsub(/[ \t\f\v]+$/, "")
      stdout_actual = @stdout
      stdout_actual = stdout_actual.gsub(/[ \t\f\v]+$/, "")
      if ChefUtils.windows?
        stderr_actual = stderr_actual.gsub("\r\n", "\n")
        stdout_actual = stdout_actual.gsub("\r\n", "\n")
      end
      if expected[:stderr].is_a?(Regexp)
        expect(stderr_actual).to match(expected[:stderr])
      else
        expect(stderr_actual).to eq(expected[:stderr])
      end
      expect(@exit_code).to eq(expected[:exit_code])
      if expected[:stdout].is_a?(Regexp)
        expect(stdout_actual).to match(expected[:stdout])
      else
        expect(stdout_actual).to eq(expected[:stdout])
      end
    end
  end
end
