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
        end
        values_to_hash(@current_resource.values)
        @current_resource
      end

      def registry
        @registry ||= Chef::Win32::Registry.new(@run_context, @new_resource.architecture)
      end

      def values_to_hash(values)
        if values
         @name_hash = Hash[values.map { |val| [val[:name], val] }]
        else
          @name_hash = {}
        end
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
        if !registry.key_exists?(@current_resource.key)
          registry.create_key(@new_resource.key, @new_resource.recursive)
        end
        @new_resource.values.each do |value|
          if @name_hash.has_key?(value[:name])
            if registry.type_matches!(@new_resource.key, value)
           # if @name_hash[value[:name]][:type] == registry.get_type_from_num(value[:type])
              if @name_hash[value[:name]][:data] != value[:data]
                registry.update_value(@new_resource.key, value)
              end
            end
          else
            registry.create_value(@new_resource.key, value)
          end
        end
      end

      def action_create_if_missing
        if !registry.key_exists?(@new_resource.key)
          registry.create_key(@new_resource.key, @new_resource.recursive)
        end
        @new_resource.values.each do |value|
          if !@name_hash.has_key?(value[:name])
            registry.create_value(@new_resource.key, value)
          end
        end
      end

      #TODO: Do we want to include a flag to delete all values?
      def action_delete
        if registry.key_exists?(@new_resource.key)
          @new_resource.values.each do |value|
            if @name_hash.has_key?(value[:name])
              registry.delete_value(@new_resource.key, value)
            end
          end
        end
      end

      def action_delete_key
        if registry.key_exists?(@new_resource.key)
          registry.delete_key(@new_resource.key, @new_resource.recursive)
        end
      end

    end
  end
end

