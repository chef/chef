#
# Author:: Jan Zimmek (<jan.zimmek@web.de>)
# Copyright:: Copyright 2010-2016, Jan Zimmek
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

require "chef/provider/service/init"

class Chef::Provider::Service::Arch < Chef::Provider::Service::Init

  provides :service, platform_family: "arch"

  def self.supports?(resource, action)
    Chef::Platform::ServiceHelpers.config_for_service(resource.service_name).include?(:etc_rcd)
  end

  def initialize(new_resource, run_context)
    super
    @init_command = "/etc/rc.d/#{@new_resource.service_name}"
  end

  def load_current_resource
    raise Chef::Exceptions::Service, "Could not find /etc/rc.conf" unless ::File.exists?("/etc/rc.conf")
    raise Chef::Exceptions::Service, "No DAEMONS found in /etc/rc.conf" unless ::File.read("/etc/rc.conf") =~ /DAEMONS=\((.*)\)/m
    super

    @current_resource.enabled(daemons.include?(@current_resource.service_name))
    @current_resource
  end

  # Get list of all daemons from the file '/etc/rc.conf'.
  # Mutiple lines and background form are supported. Example:
  #   DAEMONS=(\
  #     foobar \
  #     @example \
  #     !net \
  #   )
  def daemons
    entries = []
    if ::File.read("/etc/rc.conf") =~ /DAEMONS=\((.*)\)/m
      entries += $1.gsub(/\\?[\r\n]/, " ").gsub(/# *[^ ]+/, " ").split(" ") if $1.length > 0
    end

    yield(entries) if block_given?

    entries
  end

  # FIXME: Multiple entries of DAEMONS will cause very bad results :)
  def update_daemons(entries)
    content = ::File.read("/etc/rc.conf").gsub(/DAEMONS=\((.*)\)/m, "DAEMONS=(#{entries.join(' ')})")
    ::File.open("/etc/rc.conf", "w") do |f|
      f.write(content)
    end
  end

  def enable_service
    new_daemons = []
    entries = daemons

    if entries.include?(new_resource.service_name) || entries.include?("@#{new_resource.service_name}")
      # exists and already enabled (or already enabled as a background service)
      # new_daemons += entries
    else
      if entries.include?("!#{new_resource.service_name}")
        # exists but disabled
        entries.each do |daemon|
          if daemon == "!#{new_resource.service_name}"
            new_daemons << new_resource.service_name
          else
            new_daemons << daemon
          end
        end
      else
        # does not exist
        new_daemons += entries
        new_daemons << new_resource.service_name
      end
      update_daemons(new_daemons)
    end
  end

  def disable_service
    new_daemons = []
    entries = daemons

    if entries.include?("!#{new_resource.service_name}")
      # exists and disabled
      # new_daemons += entries
    else
      if entries.include?(new_resource.service_name) || entries.include?("@#{new_resource.service_name}")
        # exists but enabled (or enabled as a back-ground service)
        # FIXME: Does arch support !@foobar ?
        entries.each do |daemon|
          if [new_resource.service_name, "@#{new_resource.service_name}"].include?(daemon)
            new_daemons << "!#{new_resource.service_name}"
          else
            new_daemons << daemon
          end
        end
      end
      update_daemons(new_daemons)
    end
  end

end
