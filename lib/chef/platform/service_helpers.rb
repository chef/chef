#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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

require_relative "../chef_class"
require_relative "../mixin/train_helpers"

class Chef
  class Platform
    class ServiceHelpers
      class << self
        include Chef::Mixin::TrainHelpers

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
          providers = []

          if file_exist?(Chef.path_to("/usr/sbin/update-rc.d"))
            providers << :debian
          end

          if file_exist?(Chef.path_to("/usr/sbin/invoke-rc.d"))
            providers << :invokercd
          end

          if file_exist?(Chef.path_to("/sbin/initctl"))
            providers << :upstart
          end

          if file_exist?(Chef.path_to("/sbin/insserv"))
            providers << :insserv
          end

          if systemd_is_init?
            providers << :systemd
          end

          if file_exist?(Chef.path_to("/sbin/chkconfig"))
            providers << :redhat
          end

          providers
        end

        def config_for_service(service_name)
          configs = []

          if file_exist?(Chef.path_to("/etc/init.d/#{service_name}"))
            configs += %i{initd systemd}
          end

          if file_exist?(Chef.path_to("/etc/init/#{service_name}.conf"))
            configs << :upstart
          end

          if file_exist?(Chef.path_to("/etc/xinetd.d/#{service_name}"))
            configs << :xinetd
          end

          if file_exist?(Chef.path_to("/etc/rc.d/#{service_name}"))
            configs << :etc_rcd
          end

          if file_exist?(Chef.path_to("/usr/local/etc/rc.d/#{service_name}"))
            configs << :usr_local_etc_rcd
          end

          if has_systemd_service_unit?(service_name) || has_systemd_unit?(service_name)
            configs << :systemd
          end

          configs
        end

        private

        def systemd_is_init?
          file_exist?(Chef.path_to("/proc/1/comm")) &&
            file_open(Chef.path_to("/proc/1/comm")).gets.chomp == "systemd"
        end

        def has_systemd_service_unit?(svc_name)
          %w{ /etc /usr/lib /lib /run }.any? do |load_path|
            file_exist?(
              Chef.path_to("#{load_path}/systemd/system/#{svc_name.gsub(/@.*$/, "@")}.service")
            )
          end
        end

        def has_systemd_unit?(svc_name)
          # TODO: stop supporting non-service units with service resource
          %w{ /etc /usr/lib /lib /run }.any? do |load_path|
            file_exist?(Chef.path_to("#{load_path}/systemd/system/#{svc_name}"))
          end
        end
      end
    end
  end
end
