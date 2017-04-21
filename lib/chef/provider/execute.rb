#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

require "chef/log"
require "chef/provider"
require "forwardable"

class Chef
  class Provider
    class Execute < Chef::Provider
      extend Forwardable

      provides :execute

      def_delegators :new_resource, :command, :returns, :environment, :user, :domain, :password, :group, :cwd, :umask, :creates

      def load_current_resource
        current_resource = Chef::Resource::Execute.new(new_resource.name)
        current_resource
      end

      def define_resource_requirements
        if creates && creates_relative? && !cwd
          # FIXME? move this onto the resource?
          raise Chef::Exceptions::Execute, "Please either specify a full path for the creates attribute, or specify a cwd property to the #{new_resource} resource"
        end
      end

      def timeout
        # original implementation did not specify a timeout, but ShellOut
        # *always* times out. So, set a very long default timeout
        new_resource.timeout || 3600
      end

      def action_run
        if creates && sentinel_file.exist?
          Chef::Log.debug("#{new_resource} sentinel file #{sentinel_file} exists - nothing to do")
          return false
        end

        converge_by("execute #{description}") do
          begin
            shell_out!(command, opts)
          rescue Mixlib::ShellOut::ShellCommandFailed
            if sensitive?
              raise Mixlib::ShellOut::ShellCommandFailed,
                "Command execution failed. STDOUT/STDERR suppressed for sensitive resource"
            else
              raise
            end
          end
          Chef::Log.info("#{new_resource} ran successfully")
        end
      end

      private

      def sensitive?
        !!new_resource.sensitive
      end

      def live_stream?
        Chef::Config[:stream_execute_output] || !!new_resource.live_stream
      end

      def stream_to_stdout?
        STDOUT.tty? && !Chef::Config[:daemon]
      end

      def opts
        opts = {}
        opts[:timeout]     = timeout
        opts[:returns]     = returns if returns
        opts[:environment] = environment if environment
        opts[:user]        = user if user
        opts[:domain]      = domain if domain
        opts[:password]    = password if password
        opts[:group]       = group if group
        opts[:cwd]         = cwd if cwd
        opts[:umask]       = umask if umask
        opts[:log_level]   = :info
        opts[:log_tag]     = new_resource.to_s
        if (Chef::Log.info? || live_stream?) && !sensitive?
          if run_context.events.formatter?
            opts[:live_stream] = Chef::EventDispatch::EventsOutputStream.new(run_context.events, :name => :execute)
          elsif stream_to_stdout?
            opts[:live_stream] = STDOUT
          end
        end
        opts
      end

      def description
        sensitive? ? "sensitive resource" : command
      end

      def creates_relative?
        Pathname(creates).relative?
      end

      def sentinel_file
        Pathname.new(Chef::Util::PathHelper.cleanpath(
           ( cwd && creates_relative? ) ? ::File.join(cwd, creates) : creates
        ))
      end

    end
  end
end
