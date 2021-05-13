#
# Author:: Jason Field
#
# Copyright:: 2018, Calastone Ltd.
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../resource"

class Chef
  class Resource
    class WindowsDnsZone < Chef::Resource
      unified_mode true

      provides :windows_dns_zone

      description "The windows_dns_zone resource creates an Active Directory Integrated DNS Zone on the local server."
      introduced "15.0"

      property :zone_name, String,
        description: "An optional property to set the dns zone name if it differs from the resource block's name.",
        name_property: true

      property :replication_scope, String,
        description: "The replication scope for the zone, required if server_type set to 'Domain'.",
        default: "Domain"

      property :server_type, String,
        description: "The type of DNS server, Domain or Standalone.",
        default: "Domain", equal_to: %w{Domain Standalone}

      action :create, description: "Creates and updates a DNS Zone." do
        powershell_package "xDnsServer"

        run_dsc_resource "Present"
      end

      action :delete, description: "Deletes a DNS Zone." do
        powershell_package "xDnsServer"

        run_dsc_resource "Absent"
      end

      action_class do
        private

        # @api private
        def run_dsc_resource(ensure_prop)
          if new_resource.server_type == "Domain"
            dsc_resource "xDnsServerADZone #{new_resource.zone_name} #{ensure_prop}" do
              module_name "xDnsServer"
              resource :xDnsServerADZone
              property :Ensure, ensure_prop
              property :Name, new_resource.zone_name
              property :ReplicationScope, new_resource.replication_scope
            end
          elsif new_resource.server_type == "Standalone"
            dsc_resource "xDnsServerPrimaryZone #{new_resource.zone_name} #{ensure_prop}" do
              module_name "xDnsServer"
              resource :xDnsServerPrimaryZone
              property :Ensure, ensure_prop
              property :Name, new_resource.zone_name
            end
          end
        end
      end
    end
  end
end
