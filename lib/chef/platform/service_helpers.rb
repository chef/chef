#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
require "chef-utils" unless defined?(ChefUtils::CANARY)
require_relative "../mixin/chef_utils_wiring" unless defined?(Chef::Mixin::ChefUtilsWiring)

class Chef
  class Platform
    module ServiceHelpers
      include ChefUtils::DSL::Service
      include Chef::Mixin::ChefUtilsWiring

      def service_resource_providers
        providers = []

        providers << :debian if debianrcd?
        providers << :invokercd if invokercd?
        providers << :upstart if upstart?
        providers << :insserv if insserv?
        providers << :systemd if systemd?
        providers << :redhat if redhatrcd?

        providers
      end

      def config_for_service(service_name)
        configs = []

        configs << :initd if service_script_exist?(:initd, service_name)
        configs << :upstart if service_script_exist?(:upstart, service_name)
        configs << :xinetd if service_script_exist?(:xinetd, service_name)
        configs << :systemd if service_script_exist?(:systemd, service_name)
        configs << :etc_rcd if service_script_exist?(:etc_rcd, service_name)

        configs
      end

      extend self
    end
  end
end
