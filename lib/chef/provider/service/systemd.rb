#
# Author:: Stephen Haynes (<sh@nomitor.com>)
# Author:: Davide Cavalca (<dcavalca@fb.com>)
# Copyright:: Copyright 2011-2016, Chef Software Inc.
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

require "chef/resource/service"
require "chef/provider/service/simple"
require "chef/mixin/which"

class Chef::Provider::Service::Systemd < Chef::Provider::Service::Simple

  include Chef::Mixin::Which

  provides :service, os: "linux" do |node|
    Chef::Platform::ServiceHelpers.service_resource_providers.include?(:systemd)
  end

  attr_accessor :status_check_success

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
        current_resource.masked(false)
      end
    else
      current_resource.running(is_active?)
    end

    current_resource.enabled(is_enabled?)
    current_resource.masked(is_masked?)
    current_resource
  end

  # systemd supports user services just fine
  def user_services_requirements
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

  def get_systemctl_options_args
    if new_resource.user
      uid = node["etc"]["passwd"][new_resource.user]["uid"]
      options = {
        :environment => {
          "DBUS_SESSION_BUS_ADDRESS" => "unix:path=/run/user/#{uid}/bus",
        },
        :user => new_resource.user,
      }
      args = "--user"
    else
      options = {}
      args = "--system"
    end

    [options, args]
  end

  def start_service
    if current_resource.running
      Chef::Log.debug("#{new_resource} already running, not starting")
    else
      if new_resource.start_command
        super
      else
        options, args = get_systemctl_options_args
        shell_out_with_systems_locale!("#{systemctl_path} #{args} start #{new_resource.service_name}", options)
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
        options, args = get_systemctl_options_args
        shell_out_with_systems_locale!("#{systemctl_path} #{args} stop #{new_resource.service_name}", options)
      end
    end
  end

  def restart_service
    if new_resource.restart_command
      super
    else
      options, args = get_systemctl_options_args
      shell_out_with_systems_locale!("#{systemctl_path} #{args} restart #{new_resource.service_name}", options)
    end
  end

  def reload_service
    if new_resource.reload_command
      super
    else
      if current_resource.running
        options, args = get_systemctl_options_args
        shell_out_with_systems_locale!("#{systemctl_path} #{args} reload #{new_resource.service_name}", options)
      else
        start_service
      end
    end
  end

  def enable_service
    options, args = get_systemctl_options_args
    shell_out!("#{systemctl_path} #{args} enable #{new_resource.service_name}", options)
  end

  def disable_service
    options, args = get_systemctl_options_args
    shell_out!("#{systemctl_path} #{args} disable #{new_resource.service_name}", options)
  end

  def mask_service
    options, args = get_systemctl_options_args
    shell_out!("#{systemctl_path} #{args} mask #{new_resource.service_name}", options)
  end

  def unmask_service
    options, args = get_systemctl_options_args
    shell_out!("#{systemctl_path} #{args} unmask #{new_resource.service_name}", options)
  end

  def is_active?
    options, args = get_systemctl_options_args
    shell_out("#{systemctl_path} #{args} is-active #{new_resource.service_name} --quiet", options).exitstatus == 0
  end

  def is_enabled?
    options, args = get_systemctl_options_args
    shell_out("#{systemctl_path} #{args} is-enabled #{new_resource.service_name} --quiet", options).exitstatus == 0
  end

  def is_masked?
    options, args = get_systemctl_options_args
    s = shell_out("#{systemctl_path} #{args} is-enabled #{new_resource.service_name}", options)
    s.exitstatus != 0 && s.stdout.include?("masked")
  end

  private

  def systemctl_path
    if @systemctl_path.nil?
      @systemctl_path = which("systemctl")
    end
    @systemctl_path
  end

end
