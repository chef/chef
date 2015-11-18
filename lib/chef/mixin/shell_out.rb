#--
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

require 'mixlib/shellout'

class Chef
  module Mixin
    module ShellOut

      # shell_out! runs a command on the system and will raise an error if the command fails, which is what you want
      # for debugging, shell_out and shell_out! both will display command output to the tty when the log level is debug
      # Generally speaking, 'extend Chef::Mixin::ShellOut' in your recipes and include 'Chef::Mixin::ShellOut' in your LWRPs
      # You can also call Mixlib::Shellout.new directly, but you lose all of the above functionality

      # we use 'en_US.UTF-8' by default because we parse localized strings in English as an API and
      # generally must support UTF-8 unicode.
      def shell_out(*command_args)
        args = command_args.dup
        if args.last.is_a?(Hash)
          options = args.pop.dup
          env_key = options.has_key?(:env) ? :env : :environment
          options[env_key] ||= {}
          options[env_key] = options[env_key].dup
          options[env_key]['LC_ALL'] ||= Chef::Config[:internal_locale] unless options[env_key].has_key?('LC_ALL')
          options[env_key]['LANGUAGE'] ||= Chef::Config[:internal_locale] unless options[env_key].has_key?('LANGUAGE')
          options[env_key]['LANG'] ||= Chef::Config[:internal_locale] unless options[env_key].has_key?('LANG')
          args << options
        else
          args << { :environment => {
            'LC_ALL' => Chef::Config[:internal_locale],
            'LANGUAGE' => Chef::Config[:internal_locale],
            'LANG' => Chef::Config[:internal_locale],
          } }
        end

        shell_out_command(*args)
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
      # Patterned after https://github.com/opscode/chef/commit/e1509990b559984b43e428d4d801c394e970f432
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

      private

      def shell_out_command(*command_args)
        cmd = Mixlib::ShellOut.new(*run_command_compatible_options(command_args))
        cmd.live_stream ||= io_for_live_stream
        cmd.run_command
        cmd
      end

      def deprecate_option(old_option, new_option)
        Chef::Log.logger.warn "DEPRECATION: Chef::Mixin::ShellOut option :#{old_option} is deprecated. Use :#{new_option}"
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
require 'chef/config'
