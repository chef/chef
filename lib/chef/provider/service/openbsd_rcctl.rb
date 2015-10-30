#
# Author:: Scott Bonds (<scott@ggr.com>)
# Author:: Joe Miller (<joeym@joeym.net>)
# Copyright:: Copyright (c) 2014 Scott Bonds
# Copyright:: Copyright (c) 2015 Joe Miller
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
require 'chef/mixin/shell_out'
require 'chef/provider/service/init'
require 'chef/resource/service'

class Chef
  class Provider
    class Service
      class OpenbsdRcctl < Chef::Provider::Service::Init

        provides :service, platform_family: 'openbsd', override: true do |node|
          Chef::Platform::ServiceHelpers.service_resource_providers.include?(:rcctl)
        end

        include Chef::Mixin::ShellOut

        def initialize(new_resource, run_context)
          super
          new_resource.supports[:status] = true
          new_resource.status_command("rcctl check #{new_resource.service_name}")
          new_resource.start_command("rcctl start #{new_resource.service_name}")
          new_resource.stop_command("rcctl stop #{new_resource.service_name}")
          new_resource.restart_command("rcctl restart #{new_resource.service_name}")
          new_resource.reload_command("rcctl reload #{new_resource.service_name}")
        end

        def load_current_resource
          @current_resource = Chef::Resource::Service.new(new_resource.name)
          current_resource.service_name(new_resource.service_name)

          determine_current_status!
          determine_current_parameters!

          current_resource.enabled is_enabled?
        end

        def define_resource_requirements
          shared_resource_requirements

          requirements.assert(:start, :enable, :reload, :restart, :status) do |a|
            a.assertion { service_exists? }
            a.failure_message Chef::Exceptions::Service, "#{new_resource}: rcctl does not recognize this service."
          end
        end

        # Enable service and optionally set any additional variables such as command line flags
        # that are stored in the `parameters` hash.
        #
        # As of OpenBSD 5.7 the following variables can be set (rcctl(8)):
        #
        #   flags, timeout, user.
        #
        # This code does not strictly enforce these variables since rcctl(8) will
        # exit non-zero if you give it something it does not recognize.
        #
        def action_enable
          if current_resource.enabled && !parameters_need_update?
            Chef::Log.debug("#{new_resource} already enabled - nothing to do")
          else
            converge_by("enable service #{new_resource}") do
              update_params!
              enable_service
              Chef::Log.info("#{new_resource} enabled")
            end
          end
          load_new_resource_state
          new_resource.enabled(true)
        end

        def enable_service
          shell_out!("rcctl enable #{new_resource.service_name}")
        end

        def disable_service
          shell_out!("rcctl disable #{new_resource.service_name}")
        end

        private

        # `rcctl get <service> status` returns:
        # - 0: service is enabled
        # - 1: service is not enabled
        # - 2: service does not exist
        def rcctl_status
          shell_out!("rcctl get #{new_resource.service_name} status", env: nil, returns: [0, 1, 2]).status
        end

        def service_exists?
          rcctl_status != 2
        end

        def is_enabled?
          rcctl_status == 0
        end

        def rcctl_enable
          shell_out!("rcctl enable #{new_resource.service_name}")
        end

        # ex:
        #   $ rcctl get sshd
        #   sshd_flags=foo
        #   sshd_timeout=30
        #   sshd_user=root
        def determine_current_parameters!
          current_resource.parameters Hash.new
          shell_out!("rcctl get #{new_resource.service_name}", returns: [0, 1]).stdout.each_line do |line|
            if line =~ /^#{Regexp.escape(new_resource.service_name)}_(.+?)=(.*)/
              current_resource.parameters[Regexp.last_match(1)] = Regexp.last_match(2)
            else
              Chef::Log.warn("Problem parsing '#{line}' from 'rcctl get #{new_resource.service_name}'")
              next
            end
          end
          Chef::Log.debug("current params from #{new_resource}: #{current_resource.parameters}")
        end

        # check the current parameters against any newly specified parameters.
        def parameters_need_update?
          if new_resource.parameters && current_resource.parameters
            new_resource.parameters.each do |k, v|
              return true if current_resource.parameters[k.to_s] != v.to_s
            end
          end
          false
        end

        def update_params!
          new_resource.parameters.each do |k, v|
            Chef::Log.debug("Updating #{new_resource} parameter '#{k}' to '#{v}'")
            shell_out!("rcctl set #{new_resource.service_name} \"#{k}\" \"#{v}\"")
          end
        end
      end
    end
  end
end
