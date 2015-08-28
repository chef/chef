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

class Chef
  class Platform
    class ServiceHelpers
      class << self
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

            if ::File.exist?("/sbin/initctl")
              service_resource_providers << :upstart
            end

            if ::File.exist?("/sbin/chkconfig")
              service_resource_providers << :redhat
            end

            if systemd_is_init?
              service_resource_providers << :systemd
            end

          end
        end

        def config_for_service(service_name)
          configs = []

          if ::File.exist?("/etc/init.d/#{service_name}")
            configs << :initd
            configs << :systemd if systemd_is_init?
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

          if has_systemd_service_unit?(service_name)
            configs << :systemd
          end

          configs
        end

        private

        def systemd_is_init?
          ::File.exist?("/proc/1/comm") &&
            IO.read("/proc/1/comm").chomp == "systemd"
        end

        def has_systemd_service_unit?(svc_name)
          %w( /etc /run /usr/lib ).any? do |cfg_base|
            ::File.exist?("#{cfg_base}/systemd/system/#{svc_name}.service")
          end
        end
      end
    end
  end
end
