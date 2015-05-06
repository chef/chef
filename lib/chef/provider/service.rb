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

     def load_new_resource_state
        # If the user didn't specify a change in enabled state,
        # it will be the same as the old resource
       if ( @new_resource.enabled.nil? )
         @new_resource.enabled(@current_resource.enabled)
       end
       if ( @new_resource.running.nil? )
         @new_resource.running(@current_resource.running)
       end
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
          converge_by("enable service #{@new_resource}") do
            enable_service
            Chef::Log.info("#{@new_resource} enabled")
          end
        end
        load_new_resource_state
        @new_resource.enabled(true)
      end

      def action_disable
        if @current_resource.enabled
          converge_by("disable service #{@new_resource}") do
            disable_service
            Chef::Log.info("#{@new_resource} disabled")
          end
        else
          Chef::Log.debug("#{@new_resource} already disabled - nothing to do")
        end
        load_new_resource_state
        @new_resource.enabled(false)
      end

      def action_start
        unless @current_resource.running
          converge_by("start service #{@new_resource}") do
            start_service
            Chef::Log.info("#{@new_resource} started")
          end
        else
          Chef::Log.debug("#{@new_resource} already running - nothing to do")
        end
        load_new_resource_state
        @new_resource.running(true)
      end

      def action_stop
        if @current_resource.running
          converge_by("stop service #{@new_resource}") do
            stop_service
            Chef::Log.info("#{@new_resource} stopped")
          end
        else
          Chef::Log.debug("#{@new_resource} already stopped - nothing to do")
        end
        load_new_resource_state
        @new_resource.running(false)
      end

      def action_restart
        converge_by("restart service #{@new_resource}") do
          restart_service
          Chef::Log.info("#{@new_resource} restarted")
        end
        load_new_resource_state
        @new_resource.running(true)
      end

      def action_reload
        if @current_resource.running
          converge_by("reload service #{@new_resource}") do
            reload_service
            Chef::Log.info("#{@new_resource} reloaded")
          end
        end
        load_new_resource_state
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
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :reload"
      end

      protected

      def default_init_command
        if @new_resource.init_command
          @new_resource.init_command
        elsif self.instance_variable_defined?(:@init_command)
          @init_command
        end
      end

      def custom_command_for_action?(action)
        method_name = "#{action}_command".to_sym
        @new_resource.respond_to?(method_name) &&
          !!@new_resource.send(method_name)
      end
    end
  end
end

#
# Platform-specific versions
#

#
# Linux
#

require 'chef/chef_class'
require 'chef/provider/service/systemd'
require 'chef/provider/service/insserv'
require 'chef/provider/service/redhat'
require 'chef/provider/service/arch'
require 'chef/provider/service/gentoo'
require 'chef/provider/service/upstart'
require 'chef/provider/service/debian'
require 'chef/provider/service/invokercd'
require 'chef/provider/service/freebsd'
require 'chef/provider/service/openbsd'
require 'chef/provider/service/solaris'
require 'chef/provider/service/macosx'

# default block for linux O/Sen must come before platform_family exceptions
Chef.set_provider_priority_array :service, [
  Chef::Provider::Service::Systemd,
  Chef::Provider::Service::Insserv,
  Chef::Provider::Service::Redhat,
], os: "linux"

Chef.set_provider_priority_array :service, [
  Chef::Provider::Service::Systemd,
  Chef::Provider::Service::Arch,
], platform_family: "arch"

Chef.set_provider_priority_array :service, [
  Chef::Provider::Service::Systemd,
  Chef::Provider::Service::Gentoo,
], platform_family: "gentoo"

Chef.set_provider_priority_array :service, [
  # we can determine what systemd supports accurately
  Chef::Provider::Service::Systemd,
  # on debian-ish system if an upstart script exists that must win over sysv types
  Chef::Provider::Service::Upstart,
  Chef::Provider::Service::Insserv,
  Chef::Provider::Service::Debian,
  Chef::Provider::Service::Invokercd,
], platform_family: "debian"

Chef.set_provider_priority_array :service, [
  Chef::Provider::Service::Systemd,
  Chef::Provider::Service::Insserv,
  Chef::Provider::Service::Redhat,
], platform_family: [ "rhel", "fedora", "suse" ]

#
# BSDen
#

Chef.set_provider_priority_array :service, Chef::Provider::Service::Freebsd, os: [ "freebsd", "netbsd" ]
Chef.set_provider_priority_array :service, Chef::Provider::Service::Openbsd, os: [ "openbsd" ]

#
# Solaris-en
#

Chef.set_provider_priority_array :service, Chef::Provider::Service::Solaris, os: "solaris2"

#
# Mac
#

Chef.set_provider_priority_array :service, Chef::Provider::Service::Macosx, os: "darwin"
