#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
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

require File.join(File.dirname(__FILE__), "..", "mixin", "command")

class Chef
  class Provider
    class Service < Chef::Provider

      include Chef::Mixin::Command

      def initialize(node, new_resource)
        super(node, new_resource)
        @enabled = nil
      end

      def load_current_resource
        @current_resource = Chef::Resource::Service.new(@new_resource.name)
        @current_resource.service_name(@new_resource.service_name)
      end

      def action_enable
        if @current_resource.enabled == false
          Chef::Log.debug("Trying to enable #{@new_resource}")
          status = enable_service(@new_resource.service_name)
          if status
            @new_resource.enabled == true
            Chef::Log.info("Enabled service #{@new_resource} successfully")
          end
        end
      end

      def action_disable
        if @current_resource.enabled == true
          Chef::Log.debug("Trying to disable #{@new_resource}")
          status = disable_service(@new_resource.service_name)
          if status
            @new_resource.enabled == false
            Chef::Log.info("Disabled service #{@new_resource} succesfully")
          end
        end
      end

      def action_start
        if @current_resource.running == false
          status = start_service(@new_resource.service_name)
          if status
            @new_resource.running == true
            Chef::Log.info("Started service #{@new_resource} succesfully")
          end
        end 
      end

      def action_stop
        if @current_resource.running == true
          status = stop_service(@new_resource.service_name)
          if status
            @new_resource.running == false
            Chef::Log.info("Stopped service #{@new_resource} succesfully")
          end
        end 
      end
  
    end
  end
end
