#
# Author:: John Snow (<jsnow@chef.io>)
# Copyright:: 2016-2018, John Snow
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

require "chef/resource"
require "chef/mixin/powershell_out"

class Chef
  class Resource
    class WindowsAdJoin < Chef::Resource
      resource_name :windows_adjoin
      provides :windows_adjoin

      include Chef::Mixin::PowershellOut

      description "Use the windows_adjoin resource to join a Windows Active Directory domain."
      introduced "14.0"

      property :domain_name, String,
               description: "The domain name to join.",
               name_property: true

      property :domain_user, String,
               description: "The domain user to use to join the host to the domain.",
               required: true

      property :domain_password, String,
               description: "The password for the domain user.",
               required: true

      property :ou_path, String,
               description: "The path to the OU where you would like to place the host."

      property :restart, [TrueClass, FalseClass],
               description: "Restart the system after joining the domain. This is necessary for changes to take effect.",
               default: true

      # define this again so we can default it to true. Otherwise failures print the password
      property :sensitive, [TrueClass, FalseClass],
               default: true

      action :join do
        unless on_domain?
          cmd = "$pswd = ConvertTo-SecureString \'#{new_resource.domain_password}\' -AsPlainText -Force;"
          cmd << "$credential = New-Object System.Management.Automation.PSCredential (\"#{new_resource.domain_user}\",$pswd);"
          cmd << "Add-Computer -DomainName #{new_resource.domain_name} -Credential $credential"
          cmd << " -OUPath \"#{new_resource.ou_path}\"" if new_resource.ou_path
          cmd << " -Restart" if new_resource.restart
          cmd << " -Force"

          converge_by("join Active Directory domain #{new_resource.domain_name}") do
            ps_run = powershell_out(cmd)
            raise "Failed to join the domain #{new_resource.domain_name}: #{ps_run.stderr}}" if ps_run.error?
          end
        end
      end

      action_class do
        def on_domain?
          node_domain = powershell_out!('(Get-WmiObject Win32_ComputerSystem).Domain')
          raise "Failed to check if the system is joined to the domain #{new_resource.domain_name}: #{node_domain.stderr}}" if node_domain.error?
          node_domain.stdout.downcase.strip == new_resource.domain_name.downcase
        end
      end
    end
  end
end
