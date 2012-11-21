#
# Author:: Prajakta Purohit (<prajakta@opscode.com>)
# Cookbook Name:: windows
# Provider:: registry
#
# Copyright:: 2010, VMware, Inc.
# Copyright:: 2011, Opscode, Inc.
# Copyright:: 2011, Business Intelligence Associates, Inc
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

require 'chef/config'
require 'chef/log'
require 'chef/resource/file'
require 'chef/mixin/checksum'
require 'chef/provider'
require 'etc'
require 'fileutils'
require 'chef/scan_access_control'
require 'chef/mixin/shell_out'
require 'chef/win32/registry'

class Chef

  class Provider
    class RegistryKey < Chef::Provider
      include Chef::Mixin::Checksum
      include Chef::Mixin::ShellOut

      def load_current_resource
        @current_resource ||= Chef::Resource::RegistryKey.new(@new_resource.key, run_context)
        @current_resource.key(@new_resource.key)
        @current_resource.architecture(@new_resource.architecture)
        @current_resource.recursive(@new_resource.recursive)
        if registry.key_exists?(@new_resource.key)
          @current_resource.values(registry.get_values(@new_resource.key))
        else
          @current_resource.values(@new_resource.values)
        end
        values_to_hash(@current_resource.values)
        @current_resource
      end

      def registry
        @registry ||= Chef::Win32::Registry.new(@run_context, @new_resource.architecture)
      end

      def values_to_hash(values)
        if values
         @name_hash = Hash[values.map { |val| [val.delete(:name), val] }]
        else
          @name_hash = {}
        end
        puts @name_hash
      end

      def define_resource_requirements
        requirements.assert(:create, :create_if_missing, :delete, :delete_key) do |a|
    #      a.hive_exists!(@new_resource.key)
        end
        requirements.assert(:create) do |a|
          #If key exists and value exists but type different fail
        end
      #  requirements.assert(:create, :create_if_missing) do |a|
          #If the type is anything different from the list of types specified fail
      #  end
        requirements.assert(:create, :create_if_missing) do |a|
          #If keys missing in the path and recursive == false
        end
        requirements.assert(:delete) do |a|
          #If key to be deleted has subkeys but recurssive == false
        end
      end

      def action_create
        if !@current_resource.key
          registry.create_key(@new_resource.key, @new_resource.recursive)
        end
        @new_resource.values.each do |value|
          if @name_hash.has_key?(value[:name])
            if @name_hash[value[:name]][:type] == registry.get_type_from_num(value[:type])
              if @name_hash[value[:name]][:data] != value[:data]
                registry.update_value(@new_resource.key, value)
              end
            else
              # Raise exception that types are different
            end
          else
            registry.create_value(@new_resource.key, value)
          end
        end
      end

#      def action_create_if_missing
#        if key_exists?(@new_resource.key)
#          for each_value_in_@new_resource.value do
#            if !value_exists(@new_resource.key, @new_resource.value, architecture)
#              registry_create_value(@new_resource.key)
#            end
#          end
#        elsif intermediate_keys_missing?(@new_resource.key)
#          if @new_resource.recurssive == true
#            create_all_keys(@new_resource.key, @new_resource.value, architecture, create_intermediate=true)
#          end
#        else
#          create_all_keys(@new_resource.key, @new_resource.value, architecture, create_intermediate=false)
#        end
#      end
#
#      def action_delete
#        if key_exists?(@new_resource.key, @new_resource.value, architecture)
#          registry_delete(@new_resource.key, @new_resource.value, architecture)
#        end
#      end
#
#      def action_key_delete
#        if key_exists?(@new_resource.key, @new_resource.value, architecture)
#          if has_subkeys?
#            if @new_resource.recurssive == true
#              registry_delete(@new_resource.key, @new_resource.value, architecture)
#            end
#          end
#        end
#      end



#      def load_current_resource
#        @current_resource ||= Chef::Resource::Registry.new(@new_resource.key_name)
#        @current_resource.values(@new_resource.values)
#        path = @new_resource.key_name.split("\\")
#        path.shift
#        key = path.join("\\")
#        if Chef::Win32::Registry.key_exists?(@new_resource.key_name, true)
#          if Chef::Win32::Registry.value_exists?(@new_resource.key_name, @new_resource.values)
#            hive = Chef::Win32::Registry.get_hive(@new_resource.get_hive)
#            hive.open(key, ::Win32::Registry::KEY_ALL_ACCESS) do |reg|
#              @new_resource.values.each do |k, val|
#                @current_resource.type, @current_resource.values = reg.read(k)
#              end
#            end
#          end
#        end
#        @current_resource
#      end
#
#      def compare_content(current_resource, new_resource)
#        current_resource == new_resource
#      end
#
#      def action_create
#        if Chef::Win32::Registry.key_exists?(@new_resource.key_name, true)
#          if Chef::Win32::Registry.value_exists?(@new_resource.key_name, @new_resource.values)
#            if compare_content(@current_resource.values @new_resource.values)
#              registry_update(:modify)
#            end
#          end
#        end
#        registry_update(:create)
#      end
#
#      def action_remove
#        Chef::Win32::Registry::delete_value(@new_resource.key_name,@new_resource.values)
#      end
#
#      private
#      def registry_update(mode)
#
#        Chef::Log.debug("Registry Mode (#{mode})")
#        updated = Chef::Win32::Registry::set_value(mode,@new_resource.key_name,@new_resource.values,@new_resource.type)
#        @new_resource.updated_by_last_action(updated)
#      end
    end
  end
end

