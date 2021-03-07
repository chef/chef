#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
# Author:: Davide Cavalca (<dcavalca@fb.com>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../provider"
require "chef-utils" unless defined?(ChefUtils::CANARY)

class Chef
  class Provider
    class Service < Chef::Provider
      include Chef::Platform::ServiceHelpers
      extend Chef::Platform::ServiceHelpers

      def supports
        @supports ||= new_resource.supports.dup
      end

      def initialize(new_resource, run_context)
        super
        @enabled = nil
      end

      def load_current_resource
        supports[:status] = false if supports[:status].nil?
        supports[:reload] = false if supports[:reload].nil?
        supports[:restart] = false if supports[:restart].nil?
      end

      # the new_resource#enabled and #running variables are not user input, but when we
      # do (e.g.) action_enable we want to set new_resource.enabled so that the comparison
      # between desired and current state produces the correct change in reporting.
      # XXX?: the #nil? check below will likely fail if this is a cloned resource or if
      # we just run multiple actions.
      def load_new_resource_state
        if new_resource.enabled.nil?
          new_resource.enabled(current_resource.enabled)
        end
        if new_resource.running.nil?
          new_resource.running(current_resource.running)
        end
        if new_resource.masked.nil?
          new_resource.masked(current_resource.masked)
        end
      end

      # subclasses should override this if they do implement user services
      def user_services_requirements
        requirements.assert(:all_actions) do |a|
          a.assertion { new_resource.user.nil? }
          a.failure_message Chef::Exceptions::UnsupportedAction, "#{self} does not support user services"
        end
      end

      def shared_resource_requirements
        user_services_requirements
      end

      def define_resource_requirements
        requirements.assert(:reload) do |a|
          a.assertion { supports[:reload] || new_resource.reload_command }
          a.failure_message Chef::Exceptions::UnsupportedAction, "#{self} does not support :reload"
          # if a service is not declared to support reload, that won't
          # typically change during the course of a run - so no whyrun
          # alternative here.
        end
      end

      action :enable do
        if current_resource.enabled
          logger.debug("#{new_resource} already enabled - nothing to do")
        else
          converge_by("enable service #{new_resource}") do
            enable_service
            logger.info("#{new_resource} enabled")
          end
        end
        load_new_resource_state
        new_resource.enabled(true)
      end

      action :disable do
        if current_resource.enabled
          converge_by("disable service #{new_resource}") do
            disable_service
            logger.info("#{new_resource} disabled")
          end
        else
          logger.debug("#{new_resource} already disabled - nothing to do")
        end
        load_new_resource_state
        new_resource.enabled(false)
      end

      action :mask do
        if current_resource.masked
          logger.debug("#{new_resource} already masked - nothing to do")
        else
          converge_by("mask service #{new_resource}") do
            mask_service
            logger.info("#{new_resource} masked")
          end
        end
        load_new_resource_state
        new_resource.masked(true)
      end

      action :unmask do
        if current_resource.masked
          converge_by("unmask service #{new_resource}") do
            unmask_service
            logger.info("#{new_resource} unmasked")
          end
        else
          logger.debug("#{new_resource} already unmasked - nothing to do")
        end
        load_new_resource_state
        new_resource.masked(false)
      end

      action :start do
        unless current_resource.running
          converge_by("start service #{new_resource}") do
            start_service
            logger.info("#{new_resource} started")
          end
        else
          logger.debug("#{new_resource} already running - nothing to do")
        end
        load_new_resource_state
        new_resource.running(true)
      end

      action :stop do
        if current_resource.running
          converge_by("stop service #{new_resource}") do
            stop_service
            logger.info("#{new_resource} stopped")
          end
        else
          logger.debug("#{new_resource} already stopped - nothing to do")
        end
        load_new_resource_state
        new_resource.running(false)
      end

      action :restart do
        converge_by("restart service #{new_resource}") do
          restart_service
          logger.info("#{new_resource} restarted")
        end
        load_new_resource_state
        new_resource.running(true)
      end

      action :reload do
        if current_resource.running
          converge_by("reload service #{new_resource}") do
            reload_service
            logger.info("#{new_resource} reloaded")
          end
        end
        load_new_resource_state
      end

      def enable_service
        raise Chef::Exceptions::UnsupportedAction, "#{self} does not support :enable"
      end

      def disable_service
        raise Chef::Exceptions::UnsupportedAction, "#{self} does not support :disable"
      end

      def mask_service
        raise Chef::Exceptions::UnsupportedAction, "#{self} does not support :mask"
      end

      def unmask_service
        raise Chef::Exceptions::UnsupportedAction, "#{self} does not support :unmask"
      end

      def start_service
        raise Chef::Exceptions::UnsupportedAction, "#{self} does not support :start"
      end

      def stop_service
        raise Chef::Exceptions::UnsupportedAction, "#{self} does not support :stop"
      end

      def restart_service
        raise Chef::Exceptions::UnsupportedAction, "#{self} does not support :restart"
      end

      def reload_service
        raise Chef::Exceptions::UnsupportedAction, "#{self} does not support :reload"
      end

      protected

      def default_init_command
        if new_resource.init_command
          new_resource.init_command
        elsif instance_variable_defined?(:@init_command)
          @init_command
        end
      end

      def custom_command_for_action?(action)
        method_name = "#{action}_command".to_sym
        new_resource.respond_to?(method_name) &&
          !!new_resource.send(method_name)
      end

      module ServicePriorityInit

        #
        # Platform-specific versions
        #

        #
        # Linux
        #

        require_relative "../chef_class"
        require_relative "service/systemd"
        require_relative "service/insserv"
        require_relative "service/redhat"
        require_relative "service/arch"
        require_relative "service/gentoo"
        require_relative "service/upstart"
        require_relative "service/debian"
        require_relative "service/invokercd"

        Chef.set_provider_priority_array :service, [ Systemd, Arch ], platform_family: "arch"
        Chef.set_provider_priority_array :service, [ Systemd, Gentoo ], platform_family: "gentoo"
        Chef.set_provider_priority_array :service, [ Systemd, Upstart, Insserv, Debian, Invokercd ], platform_family: "debian"
        Chef.set_provider_priority_array :service, [ Systemd, Insserv, Redhat ], platform_family: "rpm_based"
      end
    end
  end
end
