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
    class WindowsDfsFolder < Chef::Resource
      unified_mode true

      provides :windows_dfs_folder

      description "Use the **windows_dfs_folder** resource to creates a folder within DFS as many levels deep as required."
      introduced "15.0"

      property :folder_path, String,
        description: "An optional property to set the path of the dfs folder if it differs from the resource block's name.",
        name_property: true

      property :namespace_name, String,
        description: "The namespace this should be created within.",
        required: true

      property :target_path, String,
        description: "The target that this path will connect you to."

      property :description, String,
        description: "Description for the share."

      action :create, description: "Creates the folder in dfs namespace." do
        raise "target_path is required for install" unless property_is_set?(:target_path)
        raise "description is required for install" unless property_is_set?(:description)

        powershell_script "Create or Update DFS Folder" do
          code <<-EOH

            $needs_creating = (Get-DfsnFolder -Path '\\\\#{ENV["COMPUTERNAME"]}\\#{new_resource.namespace_name}\\#{new_resource.folder_path}' -ErrorAction SilentlyContinue) -eq $null
            if (!($needs_creating))
            {
              Remove-DfsnFolder -Path '\\\\#{ENV["COMPUTERNAME"]}\\#{new_resource.namespace_name}\\#{new_resource.folder_path}' -Force
            }
              New-DfsnFolder -Path '\\\\#{ENV["COMPUTERNAME"]}\\#{new_resource.namespace_name}\\#{new_resource.folder_path}' -TargetPath '#{new_resource.target_path}' -Description '#{new_resource.description}'
          EOH
          not_if "return ((Get-DfsnFolder -Path '\\\\#{ENV["COMPUTERNAME"]}\\#{new_resource.namespace_name}\\#{new_resource.folder_path}' -ErrorAction SilentlyContinue).Description -eq '#{new_resource.description}' -and  (Get-DfsnFolderTarget -Path '\\\\#{ENV["COMPUTERNAME"]}\\#{new_resource.namespace_name}\\#{new_resource.folder_path}').TargetPath -eq '#{new_resource.target_path}' )"
        end
      end

      action :delete, description: "Deletes the folder in the dfs namespace." do
        powershell_script "Delete DFS Namespace" do
          code <<-EOH
            Remove-DfsnFolder -Path '\\\\#{ENV["COMPUTERNAME"]}\\#{new_resource.namespace_name}\\#{new_resource.folder_path}' -Force
          EOH
          only_if "return ((Get-DfsnFolder -Path '\\\\#{ENV["COMPUTERNAME"]}\\#{new_resource.namespace_name}\\#{new_resource.folder_path}' ) -ne $null)"
        end
      end
    end
  end
end
