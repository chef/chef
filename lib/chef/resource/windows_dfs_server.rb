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
    class WindowsDfsServer < Chef::Resource
      resource_name :windows_dfs_server
      provides :windows_dfs_server

      description "The windows_dfs_server resource sets system-wide DFS settings."
      introduced "15.0"

      property :use_fqdn, [TrueClass, FalseClass],
               description: "Indicates whether a DFS namespace server uses FQDNs in referrals. If this parameter has a value of true, the server uses FQDNs in referrals. If this parameter has a value of false, the server uses NetBIOS names.",
               default: false

      property :ldap_timeout_secs, Integer,
               description: "",
               default: 30

      property :prefer_login_dc, [TrueClass, FalseClass],
               description: "",
               default: false

      property :enable_site_costed_referrals, [TrueClass, FalseClass],
               description: "",
               default: false

      property :sync_interval_secs, Integer,
               description: "",
               default: 3600

      load_current_value do
        ps_results = powershell_out("Get-DfsnServerConfiguration -ComputerName '#{ENV['COMPUTERNAME']}' | Select LdapTimeoutSec, PreferLogonDC, EnableSiteCostedReferrals, SyncIntervalSec, UseFqdn | ConvertTo-Json")

        if ps_results.error?
          raise "The dfs_server resource failed to fetch the current state via the Get-DfsnServerConfiguration PowerShell cmlet. Is the DFS Windows feature installed?"
        end

        Chef::Log.debug("The Get-DfsnServerConfiguration results were #{ps_results.stdout}")
        results = Chef::JSONCompat.from_json(ps_results.stdout)

        use_fqdn results["UseFqdn"] || false
        ldap_timeout_secs results["LdapTimeoutSec"]
        prefer_login_dc results["PreferLogonDC"] || false
        enable_site_costed_referrals results["EnableSiteCostedReferrals"] || false
        sync_interval_secs results["SyncIntervalSec"]
      end

      action :configure do
        description "Configure DFS settings."

        converge_if_changed do
          powershell_out("Set-DfsnServerConfiguration -ComputerName '#{ENV['COMPUTERNAME']}' EnableSiteCostedReferrals $#{new_resource.enable_site_costed_referrals} -UseFqdn $#{new_resource.use_fqdn} -LdapTimeoutSec #{new_resource.ldap_timeout_secs} -PreferLogonDC $#{new_resource.prefer_login_dc} -SyncIntervalSec #{new_resource.sync_interval_secs}")
        end
      end
    end
  end
end
