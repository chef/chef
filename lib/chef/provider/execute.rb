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

require 'chef/mixin/shell_out'
require 'chef/log'
require 'chef/provider'

class Chef
  class Provider
    class Execute < Chef::Provider

      include Chef::Mixin::ShellOut

      def load_current_resource
        true
      end
      
      def whyrun_supported?
        true
      end

      def action_run
        opts = {}

        if sentinel_file = @new_resource.creates
          if ::File.exists?(sentinel_file)
            Chef::Log.debug("#{@new_resource} sentinel file #{sentinel_file} exists - nothing to do")
            return false
          end
        end

        # original implementation did not specify a timeout, but ShellOut
        # *always* times out. So, set a very long default timeout
        opts[:timeout] = @new_resource.timeout || 3600
        opts[:returns] = @new_resource.returns if @new_resource.returns
        opts[:environment] = @new_resource.environment if @new_resource.environment
        opts[:user] = @new_resource.user if @new_resource.user
        opts[:group] = @new_resource.group if @new_resource.group
        opts[:cwd] = @new_resource.cwd if @new_resource.cwd
        opts[:umask] = @new_resource.umask if @new_resource.umask
        opts[:log_level] = :info
        opts[:log_tag] = @new_resource.to_s
        if STDOUT.tty? && !Chef::Config[:daemon] && Chef::Log.info?
          opts[:live_stream] = STDOUT
        end
        converge_by("execute #{@new_resource.command}") do 
          result = shell_out!(@new_resource.command, opts)
          Chef::Log.info("#{@new_resource} ran successfully")
        end
      end
    end
  end
end
