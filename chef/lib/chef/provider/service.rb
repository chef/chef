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

      def initialize(new_resource, run_context)
        super
        @enabled = nil
      end

      def whyrun_supported?
        true
      end

      def shared_resource_requirements
      end

      def define_resource_requirements
       requirements.assert(:reload) do |a|
         a.assertion { @new_resource.supports[:reload] || @new_resource.reload_command }
         a.failure_message Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :reload"
         # if a service is not declared to support reload, that won't
         # typically change during the course of a run - so no whyrun
         # alternative here. 
       end
      end

      def action_enable
        if @current_resource.enabled
          Chef::Log.debug("#{@new_resource} already enabled - nothing to do")
        else
          converge_by("Would enable service #{@new_resource}") do
            enable_service
            Chef::Log.info("#{@new_resource} enabled")
          end
        end
      end

      def action_disable
        if @current_resource.enabled
          converge_by("Would disable service #{@new_resource}") do
            disable_service
            Chef::Log.info("#{@new_resource} disabled")
          end
        else
          Chef::Log.debug("#{@new_resource} already disabled - nothing to do")
        end
      end

      def action_start
        unless @current_resource.running
          converge_by("Would start service #{@new_resource}") do
            start_service
            Chef::Log.info("#{@new_resource} started")
          end
        else
          Chef::Log.debug("#{@new_resource} already running - nothing to do")
        end
      end

      def action_stop
        if @current_resource.running
          converge_by("Would stop service #{@new_resource}") do
            stop_service
            Chef::Log.info("#{@new_resource} stopped")
          end
        else
          Chef::Log.debug("#{@new_resource} already stopped - nothing to do")
        end
      end

      def action_restart
        converge_by("Would restart service #{@new_resource}") do
          restart_service
          Chef::Log.info("#{@new_resource} restarted")
        end
      end

      def action_reload
        if @current_resource.running
          converge_by("Would disable service #{@new_resource}") do
            reload_service
            Chef::Log.info("#{@new_resource} reloaded")
          end
        end
      end

      def enable_service
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :enable"
      end

      def disable_service
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :disable"
      end

      def start_service
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :start"
      end

      def stop_service
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :stop"
      end

      def restart_service
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :restart"
      end

      def reload_service
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :restart"
      end

    end
  end
end
