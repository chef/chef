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

require 'chef/shell_out'
require 'chef/config'

class Chef
  module Mixin
    module ShellOut

      def shell_out(*command_args)
        cmd = Mixlib::ShellOut.new(*run_command_compatible_options(command_args))
        if STDOUT.tty? && !Chef::Config[:daemon] && Chef::Log.debug?
          cmd.live_stream = STDOUT
        end
        cmd.run_command
        cmd
      end

      def shell_out!(*command_args)
        cmd= shell_out(*command_args)
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

        _command_args = command_args.dup
        _options = _command_args.last

        DEPRECATED_OPTIONS.each do |old_option, new_option|
          # Edge case: someone specifies :command_log_level and 'command_log_level' in the option hash
          next unless value = _options.delete(old_option) || _options.delete(old_option.to_s)
          deprecate_option old_option, new_option
          _options[new_option] = value
        end

        return _command_args
      end

      private

      def deprecate_option(old_option, new_option)
        Chef::Log.logger.warn "DEPRECATION: Chef::Mixin::ShellOut option :#{old_option} is deprecated. Use :#{new_option}"
      end
    end
  end
end
