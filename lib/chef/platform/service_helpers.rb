#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2014-2018, Chef Software Inc.
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

require "chef/chef_class"
require "chef-helpers"

class Chef
  class Platform
    # FIXME: deprecated, use ChefHelpers::Service instead
    class ServiceHelpers
      class << self
        def service_resource_providers
          providers = []

          providers << :debian if ChefHelpers::Service.debianrcd?
          providers << :invokercd if ChefHelpers::Service.invokercd?
          providers << :upstart if ChefHelpers::Service.upstart?
          providers << :insserv if ChefHelpers::Service.insserv?
          providers << :systemd if ChefHelpers.systemd?
          providers << :redhat if ChefHelpers::Service.redhatrcd?

          providers
        end

        def config_for_service(service_name)
          configs = []

          configs << :initd if ChefHelpers::Service.service_script_exist?(:initd, service_name)
          configs << :upstart if ChefHelpers::Service.service_script_exist?(:upstart, service_name)
          configs << :xinetd if ChefHelpers::Service.service_script_exist?(:xinetd, service_name)
          configs << :systemd if ChefHelpers::Service.service_script_exist?(:systemd, service_name)
          configs << :etc_rcd if ChefHelpers::Service.service_script_exist?(:etc_rcd, service_name)

          configs
        end
      end
    end
  end
end
