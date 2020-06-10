#
# Author:: Ross Moles (<rmoles@chef.io>)
# Author:: Rachel Rice (<rrice@chef.io>)
# Author:: Davin Taddeo (<davin@chef.io>)
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
#

require_relative "../resource"

class Chef
  class Resource
    class WindowsAuditPolicy < Chef::Resource
      subcat_opts = ["Security State Change",
                     "Security System Extension",
                     "System Integrity",
                     "IPsec Driver",
                     "Other System Events",
                     "Logon",
                     "Logoff",
                     "Account Lockout",
                     "IPsec Main Mode",
                     "IPsec Quick Mode",
                     "IPsec Extended Mode",
                     "Special Logon",
                     "Other Logon/Logoff Events",
                     "Network Policy Server",
                     "User / Device Claims",
                     "Group Membership",
                     "File System",
                     "Registry",
                     "Kernel Object",
                     "SAM",
                     "Certification Services",
                     "Application Generated",
                     "Handle Manipulation",
                     "File Share",
                     "Filtering Platform Packet Drop",
                     "Filtering Platform Connection",
                     "Other Object Access Events",
                     "Detailed File Share",
                     "Removable Storage",
                     "Central Policy Staging",
                     "Sensitive Privilege Use",
                     "Non Sensitive Privilege Use",
                     "Other Privilege Use Events",
                     "Process Creation",
                     "Process Termination",
                     "DPAPI Activity",
                     "RPC Events",
                     "Plug and Play Events",
                     "Token Right Adjusted Events",
                     "Audit Policy Change",
                     "Authentication Policy Change",
                     "Authorization Policy Change",
                     "MPSSVC Rule-Level Policy Change",
                     "Filtering Platform Policy Change",
                     "Other Policy Change Events",
                     "User Account Management",
                     "Computer Account Management",
                     "Security Group Management",
                     "Distribution Group Management",
                     "Application Group Management",
                     "Other Account Management Events",
                     "Directory Service Access",
                     "Directory Service Changes",
                     "Directory Service Replication",
                     "Detailed Directory Service Replication",
                     "Credential Validation",
                     "Kerberos Service Ticket Operations",
                     "Other Account Logon Events",
                     "Kerberos Authentication Service"
                    ]
      resource_name :windows_audit_policy
      
      description "The windows_audit_policy resource allows for configuring system and per-user Windows advanced audit policy settings."
      
      property :sub_category, [String, Array],
        coerce: proc { |p| Array(p) },
        description: "The audit policy subcategory, specified by GUID or name. Defaults to system if no user is specified."
        callbacks: { "Subcategories entered should be an actual advanced audit policy subcategory" => proc { |n| (Array(n) - subcat_opts).empty? } }
      
      property :success, [true, false],
               description: "Specify success auditing. By setting this property to true the resource will enable success for the category or sub category. Success is the default and is applied if neither success nor failure are specified."
      
      property :failure, [true, false],
               description: "Specify failure auditing. By setting this property to true the resource will enable failure for the category or sub category. Success is the default and is applied if neither success nor failure are specified."
      
      property :include_user, String,
               description: "The audit policy specified by the category or subcategory is applied per-user if specified. When a user is specified, include user. Include and exclude cannot be used at the same time."
      
      property :exclude_user, String,
               description: "The audit policy specified by the category or subcategory is applied per-user if specified. When a user is specified, exclude user. Include and exclude cannot be used at the same time."
      
      property :crash_on_audit_fail, [true, false],
               description: "Setting this audit policy option to true will cause the system to crash if the auditing system is unable to log events."
      
      property :full_privilege_auditing, [true, false],
               description: "Setting this audit policy option to true will force the audit of all privilege changes except SeAuditPrivilege. Setting this property may cause the logs to fill up more quickly."
      
      property :audit_base_objects, [true, false],
               description: "Setting this audit policy option to true will force the system to assign a System Access Control List to named objects to enable auditing of base objects such as mutexes."
      
      property :audit_base_directories, [true, false],
               description: "Setting this audit policy option to true will force the system to assign a System Access Control List to named objects to enable auditing of container objects such as directories."
      
      def subcategory_configured?(subcat, successval, failval)
        setting = if successval && failval
                    "Success and Failure$"
                  elsif successval && !failval
                    "Success$"
                  elsif !successval && failval
                    "(Failure$)&!(Success and Failure$)"
                  else
                    "No Auditing"
                  end
        powershell_exec(<<-CODE).result
          $auditpol_config = auditpol /get /subcategory:"#{subcat}"
          if ($auditpol_config | Select-String "#{setting}") { return $true } else { return $false }
        CODE
      end
      
      def option_configured?(optname, optsetting)
        setting = optsetting ? "Enabled$" : "Disabled$"
        powershell_exec(<<-CODE).result
          $auditpol_config = auditpol /get /option:#{optname}
          if ($auditpol_config | Select-String "#{setting}") { return $true } else { return $false }
        CODE
      end
      
      action :set do
        unless new_resource.sub_category.empty?
          new_resource.sub_category.each do |subcategory|
            next if subcategory_configured?(subcategory, new_resource.success, new_resource.failure)
            sval = new_resource.success ? "enable" : "disable"
            fval = new_resource.failure ? "enable" : "disable"
            cmd = "auditpol /set "
            cmd << "/user:\"#{new_resource.include_user}\" /include " if new_resource.include_user
            cmd << "/user:\"#{new_resource.exclude_user}\" /exclude " if new_resource.exclude_user
            cmd << "/subcategory:\"#{subcategory}\" /success:#{sval} /failure:#{fval}"
      
            powershell_script "Update Audit Policy for Subcategory: #{subcategory}" do
              code cmd
            end
          end
        end
      
        if !new_resource.crash_on_audit_fail.nil? && option_configured?("CrashOnAuditFail", new_resource.crash_on_audit_fail)
          val = new_resource.crash_on_audit_fail ? "Enable" : "Disable"
          cmd = "auditpol /set /option:CrashOnAuditFail /value:#{val}"
          powershell_script "Configure Audit: CrashOnAuditFail to #{val}" do
            code cmd
          end
        end
      
        if !new_resource.full_privilege_auditing.nil? && option_configured?("FullPrivilegeAuditing", new_resource.full_privilege_auditing)
          val = new_resource.full_privilege_auditing ? "Enable" : "Disable"
          cmd = "auditpol /set /option:FullPrivilegeAuditing /value:#{val}"
          powershell_script "Configure Audit: FullPrivilegeAuditing to #{val}" do
            code cmd
          end
        end
      
        if !new_resource.audit_base_directories.nil? && option_configured?("AuditBaseDirectories", new_resource.audit_base_directories)
          val = new_resource.audit_base_directories ? "Enable" : "Disable"
          cmd = "auditpol /set /option:AuditBaseDirectories /value:#{val}"
          powershell_script "Configure Audit: AuditBaseDirectories to #{val}" do
            code cmd
          end
        end
      
        if !new_resource.audit_base_objects.nil? && option_configured?("AuditBaseObjects", new_resource.audit_base_objects)
          val = new_resource.audit_base_objects ? "Enable" : "Disable"
          cmd = "auditpol /set /option:AuditBaseObjects /value:#{val}"
          powershell_script "Configure Audit: AuditBaseObjects to #{val}" do
            code cmd
          end
        end
      end      
    end
  end
end
