#
# Author:: Jason Field
#
# Copyright:: 2018, Calastone Ltd.
# Copyright:: 2019, Chef Software, Inc.
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
    class WindowsDnsRecord < Chef::Resource
      resource_name :windows_dns_record
      provides :windows_dns_record

      description "The windows_dns_record resource creates a DNS record for the given domain."
      introduced "15.0"

      property :record_name, String,
               description: "An optional property to set the dns record name if it differs from the resource block's name.",
               name_property: true

      property :zone, String,
               description: "The zone to create the record in.",
               required: true

      property :target, String,
               description: "The target for the record.",
               required: true

      property :record_type, String,
               description: "The type of record to create, can be either ARecord, CNAME or PTR.",
               default: "ARecord", equal_to: %w{ARecord CNAME PTR}

      action :create do
        description "Creates and updates the DNS entry."

        powershell_package "xDnsServer" do
        end
        do_it "Present"
      end

      action :delete do
        description "Deletes a DNS entry."
        powershell_package "xDnsServer" do
        end
        do_it "Absent"
      end

      action_class do
        def do_it(ensure_prop)
          dsc_resource "xDnsRecord #{new_resource.record_name}.#{new_resource.zone} #{ensure_prop}" do
            module_name "xDnsServer"
            resource :xDnsRecord
            property :Ensure, ensure_prop
            property :Name, new_resource.record_name
            property :Zone, new_resource.zone
            property :Type, new_resource.record_type
            property :Target, new_resource.target
          end
        end
      end
    end
  end
end
