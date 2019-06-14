#--
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2010-2018, Chef Software Inc.
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

require "mixlib/shellout" unless defined?(Mixlib::ShellOut::DEFAULT_READ_TIMEOUT)
require_relative "path_sanity"

class Chef
  module Mixin
    module ShellOut
      extend Chef::Mixin::PathSanity

      # PREFERRED APIS:
      #
      # all consumers should now call shell_out!/shell_out.
      #
      # on unix the shell_out API supports the clean_array() kind of syntax (below) so that
      # array args are flat/compact/to_s'd.  on windows, array args aren't supported to its
      # up to the caller to join(" ") on arrays of strings.
      #
      # the shell_out_compacted/shell_out_compacted! APIs are private but are intended for use
      # in rspec tests, and should ideally always be used to make code refactorings that do not
      # change behavior easier:
      #
      # allow(provider).to receive(:shell_out_compacted!).with("foo", "bar", "baz")
      # provider.shell_out!("foo", [ "bar", nil, "baz"])
      # provider.shell_out!(["foo", nil, "bar" ], ["baz"])
      #
      # note that shell_out_compacted also includes adding the magical timeout option to force
      # people to setup expectations on that value explicitly.  it does not include the default_env
      # mangling in order to avoid users having to setup an expectation on anything other than
      # setting `default_env: false` and allow us to make tweak to the default_env without breaking
      # a thousand unit tests.
      #

      def shell_out(*args, **options)
        options = options.dup
        options = Chef::Mixin::ShellOut.maybe_add_timeout(self, options)
        if options.empty?
          shell_out_compacted(*Chef::Mixin::ShellOut.clean_array(*args))
        else
          shell_out_compacted(*Chef::Mixin::ShellOut.clean_array(*args), **options)
        end
      end

      def shell_out!(*args, **options)
        options = options.dup
        options = Chef::Mixin::ShellOut.maybe_add_timeout(self, options)
        if options.empty?
          shell_out_compacted!(*Chef::Mixin::ShellOut.clean_array(*args))
        else
          shell_out_compacted!(*Chef::Mixin::ShellOut.clean_array(*args), **options)
        end
      end

      # helper sugar for resources that support passing timeouts to shell_out
      #
      # module method to not pollute namespaces, but that means we need self injected as an arg
      # @api private
      def self.maybe_add_timeout(obj, options)
        options = options.dup
        # historically resources have not properly declared defaults on their timeouts, so a default default of 900s was enforced here
        default_val = 900
        return options if options.key?(:timeout)
        # FIXME: need to nuke descendents tracker out of Chef::Provider so we can just define that class here without requiring the
        # world, and then just use symbol lookup
        if obj.class.ancestors.map(&:name).include?("Chef::Provider") && obj.respond_to?(:new_resource) && obj.new_resource.respond_to?(:timeout) && !options.key?(:timeout)
          options[:timeout] = obj.new_resource.timeout ? obj.new_resource.timeout.to_f : default_val
        end
        options
      end

      # helper function to mangle options when `default_env` is true
      #
      # @api private
      def self.apply_default_env(options)
        options = options.dup
        default_env = options.delete(:default_env)
        default_env = true if default_env.nil?
        if default_env
          env_key = options.key?(:env) ? :env : :environment
          options[env_key] = {
            "LC_ALL" => Chef::Config[:internal_locale],
            "LANGUAGE" => Chef::Config[:internal_locale],
            "LANG" => Chef::Config[:internal_locale],
            env_path => sanitized_path,
          }.update(options[env_key] || {})
        end
        options
      end

      private

      # this SHOULD be used for setting up expectations in rspec, see banner comment at top.
      #
      # the private constraint is meant to avoid code calling this directly, rspec expectations are fine.
      #
      def shell_out_compacted(*args, **options)
        options = Chef::Mixin::ShellOut.apply_default_env(options)
        if options.empty?
          Chef::Mixin::ShellOut.shell_out_command(*args)
        else
          Chef::Mixin::ShellOut.shell_out_command(*args, **options)
        end
      end

      # this SHOULD be used for setting up expectations in rspec, see banner comment at top.
      #
      # the private constraint is meant to avoid code calling this directly, rspec expectations are fine.
      #
      def shell_out_compacted!(*args, **options)
        options = Chef::Mixin::ShellOut.apply_default_env(options)
        cmd = if options.empty?
                Chef::Mixin::ShellOut.shell_out_command(*args)
              else
                Chef::Mixin::ShellOut.shell_out_command(*args, **options)
              end
        cmd.error!
        cmd
      end

      # Helper for subclasses to reject nil out of an array.  It allows
      # using the array form of shell_out (which avoids the need to surround arguments with
      # quote marks to deal with shells).
      #
      # Usage:
      #   shell_out!(*clean_array("useradd", universal_options, useradd_options, new_resource.username))
      #
      # universal_options and useradd_options can be nil, empty array, empty string, strings or arrays
      # and the result makes sense.
      #
      # keeping this separate from shell_out!() makes it a bit easier to write expectations against the
      # shell_out args and be able to omit nils and such in the tests (and to test that the nils are
      # being rejected correctly).
      #
      # @param args [String] variable number of string arguments
      # @return [Array] array of strings with nil and null string rejection

      def self.clean_array(*args)
        args.flatten.compact.map(&:to_s)
      end

      def self.transport_connection
        Chef.run_context.transport_connection
      end

      def self.shell_out_command(*args, **options)
        if Chef::Config.target_mode?
          FakeShellOut.new(args, options, transport_connection.run_command(args.join(" "))) # FIXME: train should accept run_command(*args)
        else
          cmd = if options.empty?
                  Mixlib::ShellOut.new(*args)
                else
                  Mixlib::ShellOut.new(*args, **options)
                end
          cmd.live_stream ||= io_for_live_stream
          cmd.run_command
          cmd
        end
      end

      def self.io_for_live_stream
        if STDOUT.tty? && !Chef::Config[:daemon] && Chef::Log.debug?
          STDOUT
        else
          nil
        end
      end

      def self.env_path
        if Chef::Platform.windows?
          "Path"
        else
          "PATH"
        end
      end

      class FakeShellOut
        attr_reader :stdout, :stderr, :exitstatus, :status

        def initialize(args, options, result)
          @args = args
          @options = options
          @stdout = result.stdout
          @stderr = result.stderr
          @exitstatus = result.exit_status
          @status = OpenStruct.new(success?: ( exitstatus == 0 ))
        end

        def error?
          exitstatus != 0
        end

        def error!
          raise Mixlib::ShellOut::ShellCommandFailed, "Unexpected exit status of #{exitstatus} running #{@args}" if error?
        end
      end
    end
  end
end

# Break circular dep
require_relative "../config"
