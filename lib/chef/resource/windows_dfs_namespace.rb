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

require "chef/resource"

class Chef
  class Resource
    class WindowsDfsNamespace < Chef::Resource
      resource_name :windows_dfs_namespace
      provides :windows_dfs_namespace

      property :namespace_name, String, name_property: true
      property :description,    String, required: true
      property :full_users,     Array,  default: ['BUILTIN\\administrators']
      property :change_users,   Array,  default: []
      property :read_users,     Array,  default: []
      property :root,           String, default: 'C:\\DFSRoots'

      action :install do
        directory file_path do
          action :create
          recursive true
        end

        windows_share new_resource.namespace_name do
          action :create
          path file_path
          full_users new_resource.full_users
          change_users new_resource.change_users
          read_users new_resource.read_users
        end

        powershell_script "Create DFS Namespace" do
          code <<-EOH
            $needs_creating = (Get-DfsnRoot -Path '\\\\#{ENV['COMPUTERNAME']}\\#{new_resource.namespace_name}' -ErrorAction SilentlyContinue) -eq $null
            if ($needs_creating)
            {
                New-DfsnRoot -Path '\\\\#{ENV['COMPUTERNAME']}\\#{new_resource.namespace_name}' -TargetPath '\\\\#{ENV['COMPUTERNAME']}\\#{new_resource.namespace_name}' -Type Standalone -Description '#{new_resource.description}'
            }
            else
            {
                Set-DfsnRoot -Path '\\\\#{ENV['COMPUTERNAME']}\\#{new_resource.namespace_name}' -Description '#{new_resource.description}'
            }
          EOH
          not_if "return (Get-DfsnRoot -Path '\\\\#{ENV['COMPUTERNAME']}\\#{new_resource.namespace_name}' -ErrorAction SilentlyContinue).description -eq '#{new_resource.description}'"
        end
      end

      action :delete do
        powershell_script "Delete DFS Namespace" do
          code <<-EOH
            Remove-DfsnRoot -Path '\\\\#{ENV['COMPUTERNAME']}\\#{new_resource.namespace_name}' -Force
          EOH
          only_if "return ((Get-DfsnRoot -Path '\\\\#{ENV['COMPUTERNAME']}\\#{new_resource.namespace_name}') -ne $null)"
        end

        windows_share new_resource.namespace_name do
          action :delete
          path file_path
        end

        directory file_path do
          action :delete
          recursive false # I will remove the top level but not any sub levels.
        end
      end

      action_class do
        def file_path
          "#{new_resource.root}\\#{new_resource.namespace_name}"
        end
      end
    end
  end
end
