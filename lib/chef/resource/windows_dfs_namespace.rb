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
    class WindowsDfsNamespace < Chef::Resource
      unified_mode true

      provides :windows_dfs_namespace

      description "Use the **windows_dfs_namespace** resource to creates a share and DFS namespace on a Windows server."
      introduced "15.0"

      property :namespace_name, String,
        description: "An optional property to set the dfs namespace if it differs from the resource block's name.",
        name_property: true

      property :description, String,
        description: "Description of the share.",
        required: true

      property :full_users, Array,
        description: "Determines which users should have full access to the share.",
        default: ['BUILTIN\\administrators']

      property :change_users, Array,
        description: "Determines which users should have change access to the share.",
        default: []

      property :read_users, Array,
        description: "Determines which users should have read access to the share.",
        default: []

      property :root, String,
        description: "The root from which to create the DFS tree. Defaults to C:\\DFSRoots.",
        default: 'C:\\DFSRoots'

      action :create, description: "Creates the dfs namespace on the server." do
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
            $needs_creating = (Get-DfsnRoot -Path '\\\\#{ENV["COMPUTERNAME"]}\\#{new_resource.namespace_name}' -ErrorAction SilentlyContinue) -eq $null
            if ($needs_creating)
            {
                New-DfsnRoot -Path '\\\\#{ENV["COMPUTERNAME"]}\\#{new_resource.namespace_name}' -TargetPath '\\\\#{ENV["COMPUTERNAME"]}\\#{new_resource.namespace_name}' -Type Standalone -Description '#{new_resource.description}'
            }
            else
            {
                Set-DfsnRoot -Path '\\\\#{ENV["COMPUTERNAME"]}\\#{new_resource.namespace_name}' -Description '#{new_resource.description}'
            }
          EOH
          not_if "return (Get-DfsnRoot -Path '\\\\#{ENV["COMPUTERNAME"]}\\#{new_resource.namespace_name}' -ErrorAction SilentlyContinue).description -eq '#{new_resource.description}'"
        end
      end

      action :delete, description: "Deletes a DFS Namespace including the directory on disk." do
        powershell_script "Delete DFS Namespace" do
          code <<-EOH
            Remove-DfsnRoot -Path '\\\\#{ENV["COMPUTERNAME"]}\\#{new_resource.namespace_name}' -Force
          EOH
          only_if "return ((Get-DfsnRoot -Path '\\\\#{ENV["COMPUTERNAME"]}\\#{new_resource.namespace_name}') -ne $null)"
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
