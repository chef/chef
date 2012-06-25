#
# Author:: Lee Jensen (<ljensen@engineyard.com>)
# Author:: AJ Christensen (<aj@opscode.com>)
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

require 'chef/provider/service'
require 'chef/mixin/command'

class Chef::Provider::Service::Gentoo < Chef::Provider::Service::Init
  def load_current_resource

    @new_resource.supports[:status] = true
    @new_resource.supports[:restart] = true
    @found_script = false
    super

    @current_resource.enabled(
      Dir.glob("/etc/runlevels/**/#{@current_resource.service_name}").any? do |file|
        @found_script = true
        exists = ::File.exists? file
        readable = ::File.readable? file
        Chef::Log.debug "#{@new_resource} exists: #{exists}, readable: #{readable}"
        exists and readable
      end
    )
    Chef::Log.debug "#{@new_resource} enabled: #{@current_resource.enabled}"

    @current_resource
  end

  def define_resource_requirements
    requirements.assert(:all_actions) do |a|
      a.assertion { ::File.exists?("/sbin/rc-update") } 
      a.failure_message Chef::Exceptions::Service, "/sbin/rc-update does not exist"
      # no whyrun recovery -t his is a core component whose presence is
      # unlikely to be affected by what we do in the course of a chef run
    end

    requirements.assert(:all_actions) do |a|
      a.assertion { @found_script }
      # No failure, just informational output from whyrun 
      a.whyrun "Could not find service #{@new_resource.service_name} under any runlevel"
    end
  end
  
  def enable_service()
    run_command(:command => "/sbin/rc-update add #{@new_resource.service_name} default")
  end
  
  def disable_service()
    run_command(:command => "/sbin/rc-update del #{@new_resource.service_name} default")
  end
end
