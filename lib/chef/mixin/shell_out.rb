#--
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2010-2017, Chef Software Inc.
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

require "mixlib/shellout"
require "chef/mixin/path_sanity"

class Chef
  module Mixin
    module ShellOut
      include Chef::Mixin::PathSanity

      # PREFERRED APIS:
      #
      # shell_out_compact and shell_out_compact! flatten their array arguments and remove nils and pass
      # the resultant array to shell_out.  this actually eliminates spaces-in-args bugs because this:
      #
      # shell_out!("command #{arg}")
      #
      # becomes two arguments if arg has spaces and requires quotations:
      #
      # shell_out!("command '#{arg}'")
      #
      # using shell_out_compact! this becomes:
      #
      # shell_out_compact!("command", arg)
      #
      # and spaces in the arg just works and it does not become two arguments (and the shell quoting around
      # the argument must actually be removed).
      #
      # there's also an implicit join between all the array elements, and nested arrays are flattened which
      # means that odd where-do-i-put-the-spaces options handling just works, and instead of this:
      #
      #    opts = ""                     # needs to be empty string for when foo and bar are both missing
      #    opts << " -foo" if needs_foo? # needs the leading space on both of these
      #    opts << " -bar" if needs_bar?
      #    shell_out!("cmd#{opts}")      # have to think way too hard about why there's no space here
      #
      # becomes:
      #
      #    opts = []
      #    opts << "-foo" if needs_foo?
      #    opts << "-bar" if needs_bar?
      #    shell_out_compact!("cmd", opts)
      #
      # and opts can be an empty array or nil and it'll work out fine.
      #
      # generally its best to use shell_out_compact! in code and setup expectations on shell_out! in tests
      #

      def shell_out_compact(*args, **options)
        if options.empty?
          shell_out(*clean_array(*args))
        else
          shell_out(*clean_array(*args), **options)
        end
      end

      def shell_out_compact!(*args, **options)
        if options.empty?
          shell_out!(*clean_array(*args))
        else
          shell_out!(*clean_array(*args), **options)
        end
      end

      # helper sugar for resources that support passing timeouts to shell_out

      def shell_out_compact_timeout(*args, **options)
        raise "object is not a resource that supports timeouts" unless respond_to?(:new_resource) && new_resource.respond_to?(:timeout)
        options_dup = options.dup
        options_dup[:timeout] = new_resource.timeout if new_resource.timeout
        options_dup[:timeout] = 900 unless options_dup.key?(:timeout)
        shell_out_compact(*args, **options_dup)
      end

      def shell_out_compact_timeout!(*args, **options)
        raise "object is not a resource that supports timeouts" unless respond_to?(:new_resource) && new_resource.respond_to?(:timeout)
        options_dup = options.dup
        options_dup[:timeout] = new_resource.timeout if new_resource.timeout
        options_dup[:timeout] = 900 unless options_dup.key?(:timeout)
        shell_out_compact!(*args, **options_dup)
      end

      # shell_out! runs a command on the system and will raise an error if the command fails, which is what you want
      # for debugging, shell_out and shell_out! both will display command output to the tty when the log level is debug
      # Generally speaking, 'extend Chef::Mixin::ShellOut' in your recipes and include 'Chef::Mixin::ShellOut' in your LWRPs
      # You can also call Mixlib::Shellout.new directly, but you lose all of the above functionality

      # we use 'en_US.UTF-8' by default because we parse localized strings in English as an API and
      # generally must support UTF-8 unicode.
      def shell_out(*args, **options)
        options = options.dup
        env_key = options.has_key?(:env) ? :env : :environment
        options[env_key] = {
          "LC_ALL" => Chef::Config[:internal_locale],
          "LANGUAGE" => Chef::Config[:internal_locale],
          "LANG" => Chef::Config[:internal_locale],
          env_path => sanitized_path,
        }.update(options[env_key] || {})
        shell_out_command(*args, **options)
      end

      # call shell_out (using en_US.UTF-8) and raise errors
      def shell_out!(*command_args)
        cmd = shell_out(*command_args)
        cmd.error!
        cmd
      end

      def shell_out_with_systems_locale(*command_args)
        shell_out_command(*command_args)
      end

      def shell_out_with_systems_locale!(*command_args)
        cmd = shell_out_with_systems_locale(*command_args)
        cmd.error!
        cmd
      end

      # Helper for sublcasses to convert an array of string args into a string.  It
      # will compact nil or empty strings in the array and will join the array elements
      # with spaces, without introducing any double spaces for nil/empty elements.
      #
      # @param args [String] variable number of string arguments
      # @return [String] nicely concatenated string or empty string
      def a_to_s(*args)
        # can't quite deprecate this yet
        #Chef.deprecated(:package_misc, "a_to_s is deprecated use shell_out_compact or shell_out_compact_timeout instead")
        args.flatten.reject { |i| i.nil? || i == "" }.map(&:to_s).join(" ")
      end

      # Helper for sublcasses to reject nil out of an array.  It allows
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
      def clean_array(*args)
        args.flatten.compact.map(&:to_s)
      end

      private

      def shell_out_command(*command_args)
        cmd = Mixlib::ShellOut.new(*command_args)
        cmd.live_stream ||= io_for_live_stream
        cmd.run_command
        cmd
      end

      def io_for_live_stream
        if STDOUT.tty? && !Chef::Config[:daemon] && Chef::Log.debug?
          STDOUT
        else
          nil
        end
      end

      def env_path
        if Chef::Platform.windows?
          "Path"
        else
          "PATH"
        end
      end
    end
  end
end

# Break circular dep
require "chef/config"
