#--
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2010-2016, Chef Software Inc.
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

class Chef
  module Mixin
    module ShellOut

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

      DEPRECATED_OPTIONS =
        [ [:command_log_level,   :log_level],
          [:command_log_prepend, :log_tag] ]

      # CHEF-3090: Deprecate command_log_level and command_log_prepend
      # Patterned after https://github.com/chef/chef/commit/e1509990b559984b43e428d4d801c394e970f432
      def run_command_compatible_options(command_args)
        return command_args unless command_args.last.is_a?(Hash)

        my_command_args = command_args.dup
        my_options = my_command_args.last

        DEPRECATED_OPTIONS.each do |old_option, new_option|
          # Edge case: someone specifies :command_log_level and 'command_log_level' in the option hash
          next unless value = my_options.delete(old_option) || my_options.delete(old_option.to_s)
          deprecate_option old_option, new_option
          my_options[new_option] = value
        end

        return my_command_args
      end

      # Helper for sublcasses to convert an array of string args into a string.  It
      # will compact nil or empty strings in the array and will join the array elements
      # with spaces, without introducing any double spaces for nil/empty elements.
      #
      # @param args [String] variable number of string arguments
      # @return [String] nicely concatenated string or empty string
      def a_to_s(*args)
        clean_array(*args).join(" ")
      end

      # Helper for sublcasses to reject nil and empty strings out of an array.  It allows
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
        args.flatten.reject { |i| i.nil? || i == "" }.map(&:to_s)
      end

      private

      def shell_out_command(*command_args)
        cmd = Mixlib::ShellOut.new(*run_command_compatible_options(command_args))
        cmd.live_stream ||= io_for_live_stream
        cmd.run_command
        cmd
      end

      def deprecate_option(old_option, new_option)
        Chef.deprecated :internal_api, "Chef::Mixin::ShellOut option :#{old_option} is deprecated. Use :#{new_option}"
      end

      def io_for_live_stream
        if STDOUT.tty? && !Chef::Config[:daemon] && Chef::Log.debug?
          STDOUT
        else
          nil
        end
      end
    end
  end
end

# Break circular dep
require "chef/config"
