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

require 'chef/mixin/command'
require 'chef/provider'

class Chef
  class Provider
    class Service < Chef::Provider

      include Chef::Mixin::Command

      def initialize(node, new_resource, collection=nil, definitions=nil, cookbook_loader=nil)
        super(node, new_resource, collection, definitions, cookbook_loader)
        @enabled = nil
      end

      def action_enable
        unless @current_resource.enabled
          Chef::Log.debug("#{@new_resource}: attempting to enable")
          status = enable_service()
          if status
            @new_resource.updated = true
            Chef::Log.info("#{@new_resource}: enabled successfully")
          end
        else
          Chef::Log.debug("#{@new_resource}: not enabling, already enabled")
        end
      end

      def action_disable
        if @current_resource.enabled
          Chef::Log.debug("#{@new_resource}: attempting to disable")
          status = disable_service()
          if status
            @new_resource.updated = true
            Chef::Log.info("#{@new_resource}: disabled successfully")
          end
        else
          Chef::Log.debug("#{@new_resource}: not disabling, already disabled")
        end
      end

      def action_start
        unless @current_resource.running
          Chef::Log.debug("#{@new_resource}: attempting to start")
          status = start_service()
          if status
            @new_resource.updated = true
            Chef::Log.info("Started service #{@new_resource} successfully")
          end
        else
          Chef::Log.debug("#{@new_resource}: not starting, already running")
        end 
      end

      def action_stop
        if @current_resource.running
          Chef::Log.debug("#{@new_resource}: attempting to stop")
          status = stop_service()
          if status
            @new_resource.updated = true
            Chef::Log.info("#{@new_resource}: stopped successfully")
          end
        else
          Chef::Log.debug("#{@new_resource}: not stopping, already stopped")
        end 
      end
      
      def action_restart
        Chef::Log.debug("#{@new_resource}: attempting to restart")
        status = restart_service()
        if status
          @new_resource.updated = true
          Chef::Log.info("#{@new_resource}: restarted successfully")
        end
      end

      def action_reload
        unless @new_resource.supports[:reload] or @new_resource.reload_command
          raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :reload"
        else
          if @current_resource.running
            Chef::Log.debug("#{@new_resource}: attempting to reload")
            status = reload_service()
            if status
              @new_resource.updated = true
              Chef::Log.info("#{@new_resource}: reloaded successfully")
            end
          end
        end
      end

      def enable_service(name)
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :enable"
      end

      def disable_service(name)
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :disable"
      end

      def start_service(name)
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :start"
      end

      def stop_service(name)
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :stop"
      end 
      
      def restart_service(name)
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :restart"
      end

      def reload_service(name)
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :restart"
      end
 
    end
  end
end
