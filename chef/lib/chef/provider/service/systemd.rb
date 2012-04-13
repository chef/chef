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

require 'chef/provider/service'
require 'chef/provider/service/simple'
require 'chef/mixin/command'

class Chef::Provider::Service::Systemd < Chef::Provider::Service::Simple
  def load_current_resource
    @current_resource = Chef::Resource::Service.new(@new_resource.name)
    @current_resource.service_name(@new_resource.service_name)

    if @new_resource.status_command
      Chef::Log.debug("#{@new_resource} you have specified a status command, running..")

      begin
        if shell_out_with_systems_locale!(@new_resource.status_command) == 0
          @current_resource.running(true)
        end
      rescue Chef::Exceptions::Exec
        @current_resource.running(false)
        nil
      end
    else
      @current_resource.running(is_active?)
    end

    @current_resource.enabled(is_enabled?)
    @current_resource
  end

  def start_service
    if @current_resource.running
      Chef::Log.debug("#{@new_resource} already running, not starting")
    else
      if @new_resource.start_command
        super
      else
        shell_out_with_systems_locale!("/bin/systemctl start #{@new_resource.service_name}")
      end
    end
  end

  def stop_service
    unless @current_resource.running
      Chef::Log.debug("#{@new_resource} not running, not stopping")
    else
      if @new_resource.stop_command
        super
      else
        shell_out_with_systems_locale!("/bin/systemctl stop #{@new_resource.service_name}")
      end
    end
  end

  def restart_service
    if @new_resource.restart_command
      super
    else
      shell_out_with_systems_locale!("/bin/systemctl restart #{@new_resource.service_name}")
    end
  end

  def reload_service
    if @new_resource.reload_command
      super
    else
      shell_out_with_systems_locale!("/bin/systemctl reload #{@new_resource.service_name}")
    end
  end

  def enable_service
    shell_out_with_systems_locale!("/bin/systemctl enable #{@new_resource.service_name}")
  end

  def disable_service
    shell_out_with_systems_locale!("/bin/systemctl disable #{@new_resource.service_name}")
  end

  def is_active?
    shell_out_with_systems_locale("/bin/systemctl is-active #{@new_resource.service_name}") == 0
  end

  def is_enabled?
    shell_out_with_systems_locale("/bin/systemctl is-enabled #{@new_resource.service_name}") == 0
  end
end
