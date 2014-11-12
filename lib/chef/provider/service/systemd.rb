#
# Author:: Stephen Haynes (<sh@nomitor.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'chef/resource/service'
require 'chef/provider/service/simple'
require 'chef/mixin/which'

class Chef::Provider::Service::Systemd < Chef::Provider::Service::Simple

  include Chef::Mixin::Which

  provides :service, os: "linux"

  attr_accessor :status_check_success

  def self.provides?(node, resource)
    super && Chef::Platform::ServiceHelpers.service_resource_providers.include?(:systemd)
  end

  def self.supports?(resource, action)
    Chef::Platform::ServiceHelpers.config_for_service(resource.service_name).include?(:systemd)
  end

  def load_current_resource
    @current_resource = Chef::Resource::Service.new(new_resource.name)
    current_resource.service_name(new_resource.service_name)
    @status_check_success = true

    if new_resource.status_command
      Chef::Log.debug("#{new_resource} you have specified a status command, running..")

      unless shell_out(new_resource.status_command).error?
        current_resource.running(true)
      else
        @status_check_success = false
        current_resource.running(false)
        current_resource.enabled(false)
      end
    else
      current_resource.running(is_active?)
    end

    current_resource.enabled(is_enabled?)
    current_resource
  end

  def define_resource_requirements
    shared_resource_requirements
    requirements.assert(:all_actions) do |a|
      a.assertion { status_check_success }
      # We won't stop in any case, but in whyrun warn and tell what we're doing.
      a.whyrun ["Failed to determine status of #{new_resource}, using command #{new_resource.status_command}.",
        "Assuming service would have been installed and is disabled"]
    end
  end

  def start_service
    if current_resource.running
      Chef::Log.debug("#{new_resource} already running, not starting")
    else
      if new_resource.start_command
        super
      else
        shell_out_with_systems_locale!("#{systemctl_path} start #{new_resource.service_name}")
      end
    end
  end

  def stop_service
    unless current_resource.running
      Chef::Log.debug("#{new_resource} not running, not stopping")
    else
      if new_resource.stop_command
        super
      else
        shell_out_with_systems_locale!("#{systemctl_path} stop #{new_resource.service_name}")
      end
    end
  end

  def restart_service
    if new_resource.restart_command
      super
    else
      shell_out_with_systems_locale!("#{systemctl_path} restart #{new_resource.service_name}")
    end
  end

  def reload_service
    if new_resource.reload_command
      super
    else
      if current_resource.running
        shell_out_with_systems_locale!("#{systemctl_path} reload #{new_resource.service_name}")
      else
        start_service
      end
    end
  end

  def enable_service
    shell_out!("#{systemctl_path} enable #{new_resource.service_name}")
  end

  def disable_service
    shell_out!("#{systemctl_path} disable #{new_resource.service_name}")
  end

  def is_active?
    shell_out("#{systemctl_path} is-active #{new_resource.service_name} --quiet").exitstatus == 0
  end

  def is_enabled?
    shell_out("#{systemctl_path} is-enabled #{new_resource.service_name} --quiet").exitstatus == 0
  end

  private

  def systemctl_path
    if @systemctl_path.nil?
      @systemctl_path = which("systemctl")
    end
    @systemctl_path
  end

end
