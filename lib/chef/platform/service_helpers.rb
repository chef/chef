#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

# XXX: mixing shellout into a mixin into classes has to be code smell
require 'chef/mixin/shell_out'
require 'chef/mixin/which'

class Chef
  class Platform
    class ServiceHelpers
      class << self

        include Chef::Mixin::ShellOut
        include Chef::Mixin::Which

        # This helper is mostly used to sort out the mess of different
        # linux mechanisms that can be used to start services.  It does
        # not necessarily need to linux-specific, but currently all our
        # other service providers are narrowly platform-specific with no
        # alternatives.
        #
        # NOTE: if a system has (for example) chkconfig installed then we
        # should report that chkconfig is installed.  The fact that a system
        # may also have systemd installed does not mean that we do not
        # report that systemd is also installed.  This module is purely for
        # discovery of all the alternatives, handling the priority of the
        # different services is NOT a design concern of this module.
        #
        def service_resource_providers
          @service_resource_providers ||= [].tap do |service_resource_providers|

            if ::File.exist?("/usr/sbin/update-rc.d")
              service_resource_providers << :debian
            end

            if ::File.exist?("/usr/sbin/invoke-rc.d")
              service_resource_providers << :invokercd
            end

            if ::File.exist?("/sbin/insserv")
              service_resource_providers << :insserv
            end

            # debian >= 6.0 has /etc/init but does not have upstart
            if ::File.exist?("/etc/init") && ::File.exist?("/sbin/start")
              service_resource_providers << :upstart
            end

            if ::File.exist?("/sbin/chkconfig")
              service_resource_providers << :redhat
            end

            if systemd_sanity_check?
              service_resource_providers << :systemd
            end

          end
        end

        def config_for_service(service_name)
          configs = []

          if ::File.exist?("/etc/init.d/#{service_name}")
            configs << :initd
          end

          if ::File.exist?("/etc/init/#{service_name}.conf")
            configs << :upstart
          end

          if ::File.exist?("/etc/xinetd.d/#{service_name}")
            configs << :xinetd
          end

          if ::File.exist?("/etc/rc.d/#{service_name}")
            configs << :etc_rcd
          end

          if ::File.exist?("/usr/local/etc/rc.d/#{service_name}")
            configs << :usr_local_etc_rcd
          end

          if systemd_sanity_check? && platform_has_systemd_unit?(service_name)
            configs << :systemd
          end

          configs
        end

        private

        def systemctl_path
          if @systemctl_path.nil?
            @systemctl_path = which("systemctl")
          end
          @systemctl_path
        end

        def systemd_sanity_check?
          systemctl_path && File.exist?("/proc/1/comm") && File.open("/proc/1/comm").gets.chomp == "systemd"
        end

        def extract_systemd_services(command)
          output = shell_out!(command).stdout
          # first line finds e.g. "sshd.service"
          services = []
          output.each_line do |line|
            fields = line.split
            services << fields[0] if fields[1] == "loaded" || fields[1] == "not-found"
          end
          # this splits off the suffix after the last dot to return "sshd"
          services += services.select {|s| s.match(/\.service$/) }.map { |s| s.sub(/(.*)\.service$/, '\1') }
        rescue Mixlib::ShellOut::ShellCommandFailed
          false
        end

        def platform_has_systemd_unit?(service_name)
          services = extract_systemd_services("#{systemctl_path} --all") +
            extract_systemd_services("#{systemctl_path} list-unit-files")
          services.include?(service_name)
        rescue Mixlib::ShellOut::ShellCommandFailed
          false
        end
      end
    end
  end
end
