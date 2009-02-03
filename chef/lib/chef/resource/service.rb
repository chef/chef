#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
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

require 'chef/resource'

class Chef
  class Resource
    class Service < Chef::Resource
        
      def initialize(name, collection=nil, node=nil)
        super(name, collection, node)
        @resource_name = :service
        @service_name = name
        @enabled = nil
        @running = nil
        @pattern = service_name 
        @start_command = nil
        @stop_command = nil
        @status_command = nil
        @restart_command = nil
        @reload_command = nil
        @action = "nothing"
        @supports = { :restart => false, :reload => false, :status => false }
        @allowed_actions.push(:enable, :disable, :start, :stop, :restart, :reload)
      end
      
      def service_name(arg=nil)
        set_or_return(
          :service_name,
          arg,
          :kind_of => [ String ]
        )
      end
      
      # regex for match against ps -ef when !supports[:has_status] && status == nil
      def pattern(arg=nil)
        set_or_return(
          :pattern,
          arg,
          :kind_of => [ String ]
        )
      end

      # command to call to start service
      def start_command(arg=nil)
        set_or_return(
          :start_command,
          arg,
          :kind_of => [ String ]
        )
      end

      # command to call to stop service
      def stop_command(arg=nil)
        set_or_return(
          :stop_command,
          arg,
          :kind_of => [ String ]
        )
      end

      # command to call to get status of service
      def status_command(arg=nil)
        set_or_return(
          :status_command,
          arg,
          :kind_of => [ String ]
        )
      end

      # command to call to restart service
      def restart_command(arg=nil)
        set_or_return(
          :restart_command,
          arg,
          :kind_of => [ String ]
        )
      end

      def reload_command(arg=nil)
        set_or_return(
          :reload_command,
          arg,
          :kind_of => [ String ]
        )
      end

      # if the service is enabled or not
      def enabled(arg=nil)
        set_or_return(
          :enabled,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      # if the service is running or not
      def running(arg=nil)
        set_or_return(
          :running,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      def supports(args={})
        if args.is_a? Array
          args.each { |arg| @supports[arg] = true }
        elsif args.any?
          @supports = args
        else
          @supports
        end
      end

  
    end
  end
end
