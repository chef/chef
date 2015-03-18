#
# Author:: Adam Jacob (<adam@opscode.com>)
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

require 'chef/log'
require 'chef/provider'
require 'forwardable'

class Chef
  class Provider
    class Execute < Chef::Provider
      extend Forwardable

      provides :execute

      def_delegators :@new_resource, :command, :returns, :environment, :user, :group, :cwd, :umask, :creates

      def load_current_resource
        current_resource = Chef::Resource::Execute.new(new_resource.name)
        current_resource
      end

      def whyrun_supported?
        true
      end

      def define_resource_requirements
         # @todo: this should change to raise in some appropriate major version bump.
         if creates && creates_relative? && !cwd
           Chef::Log.warn "Providing a relative path for the creates attribute without the cwd is deprecated and will be changed to fail (CHEF-3819)"
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
          result = shell_out!(command, opts)
          Chef::Log.info("#{new_resource} ran successfully")
        end
      end

      private

      def sensitive?
        !!new_resource.sensitive
      end

      def opts
        opts = {}
        opts[:timeout]     = timeout
        opts[:returns]     = returns if returns
        opts[:environment] = environment if environment
        opts[:user]        = user if user
        opts[:group]       = group if group
        opts[:cwd]         = cwd if cwd
        opts[:umask]       = umask if umask
        opts[:log_level]   = :info
        opts[:log_tag]     = new_resource.to_s
        if STDOUT.tty? && !Chef::Config[:daemon] && Chef::Log.info? && !sensitive?
          opts[:live_stream] = STDOUT
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
