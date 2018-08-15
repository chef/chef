#
# Author:: Prajakta Purohit (<prajakta@chef.io>)
# Author:: Lamont Granquist (<lamont@chef.io>)
#
# Copyright:: Copyright 2011-2017, Chef Software Inc.
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

require "chef/config"
require "chef/log"
require "chef/resource/file"
require "chef/mixin/checksum"
require "chef/provider"
require "etc"
require "fileutils"
require "chef/scan_access_control"
require "chef/win32/registry"

class Chef

  class Provider
    class RegistryKey < Chef::Provider
      provides :registry_key

      include Chef::Mixin::Checksum

      def running_on_windows!
        unless Chef::Platform.windows?
          raise Chef::Exceptions::Win32NotWindows, "Attempt to manipulate the windows registry on a non-windows node"
        end
      end

      def load_current_resource
        running_on_windows!
        @current_resource ||= Chef::Resource::RegistryKey.new(new_resource.key, run_context)
        current_resource.key(new_resource.key)
        current_resource.architecture(new_resource.architecture)
        current_resource.recursive(new_resource.recursive)
        if registry.key_exists?(new_resource.key)
          current_resource.values(registry.get_values(new_resource.key))
        end
        values_to_hash(current_resource.unscrubbed_values)
        current_resource
      end

      def registry
        @registry ||= Chef::Win32::Registry.new(@run_context, new_resource.architecture)
      end

      def values_to_hash(values)
        if values
          @name_hash = Hash[values.map { |val| [val[:name].downcase, val] }]
        else
          @name_hash = {}
        end
      end

      def key_missing?(values, name)
        values.each do |v|
          return true unless v.key?(name)
        end
        false
      end

      def define_resource_requirements
        requirements.assert(:create, :create_if_missing, :delete, :delete_key) do |a|
          a.assertion { registry.hive_exists?(new_resource.key) }
          a.failure_message(Chef::Exceptions::Win32RegHiveMissing, "Hive #{new_resource.key.split("\\").shift} does not exist")
        end

        requirements.assert(:create) do |a|
          a.assertion { registry.key_exists?(new_resource.key) }
          a.whyrun("Key #{new_resource.key} does not exist. Unless it would have been created before, attempt to modify its values would fail.")
        end

        requirements.assert(:create, :create_if_missing) do |a|
          # If keys missing in the path and recursive == false
          a.assertion { !registry.keys_missing?(current_resource.key) || new_resource.recursive }
          a.failure_message(Chef::Exceptions::Win32RegNoRecursive, "Intermediate keys missing but recursive is set to false")
          a.whyrun("Intermediate keys in #{new_resource.key} do not exist. Unless they would have been created earlier, attempt to modify them would fail.")
        end

        requirements.assert(:delete_key) do |a|
          # If key to be deleted has subkeys but recurssive == false
          a.assertion { !registry.key_exists?(new_resource.key) || !registry.has_subkeys?(new_resource.key) || new_resource.recursive }
          a.failure_message(Chef::Exceptions::Win32RegNoRecursive, "#{new_resource.key} has subkeys but recursive is set to false.")
          a.whyrun("#{current_resource.key} has subkeys, but recursive is set to false. attempt to delete would fails unless subkeys were deleted prior to this action.")
        end

        requirements.assert(:create, :create_if_missing) do |a|
          # If type key missing in the RegistryKey values hash
          a.assertion { !key_missing?(new_resource.values, :type) }
          a.failure_message(Chef::Exceptions::RegKeyValuesTypeMissing, "Missing type key in RegistryKey values hash")
          a.whyrun("Type key does not exist. Attempt would fail unless the complete values hash containing all the keys does not exist for registry_key resource's create action.")
        end

        requirements.assert(:create, :create_if_missing) do |a|
          # If data key missing in the RegistryKey values hash
          a.assertion { !key_missing?(new_resource.values, :data) }
          a.failure_message(Chef::Exceptions::RegKeyValuesDataMissing, "Missing data key in RegistryKey values hash")
          a.whyrun("Data key does not exist. Attempt would fail unless the complete values hash containing all the keys does not exist for registry_key resource's create action.")
        end
      end

      def action_create
        unless registry.key_exists?(current_resource.key)
          converge_by("create key #{new_resource.key}") do
            registry.create_key(new_resource.key, new_resource.recursive)
          end
        end
        new_resource.unscrubbed_values.each do |value|
          if @name_hash.key?(value[:name].downcase)
            current_value = @name_hash[value[:name].downcase]
            if [:dword, :dword_big_endian, :qword].include? value[:type]
              value[:data] = value[:data].to_i
            end
            unless current_value[:type] == value[:type] && current_value[:data] == value[:data]
              converge_by_value = value
              converge_by_value[:data] = "*sensitive value suppressed*" if new_resource.sensitive

              converge_by("set value #{converge_by_value}") do
                registry.set_value(new_resource.key, value)
              end
            end
          else
            converge_by_value = value
            converge_by_value[:data] = "*sensitive value suppressed*" if new_resource.sensitive

            converge_by("set value #{converge_by_value}") do
              registry.set_value(new_resource.key, value)
            end
          end
        end
      end

      def action_create_if_missing
        unless registry.key_exists?(new_resource.key)
          converge_by("create key #{new_resource.key}") do
            registry.create_key(new_resource.key, new_resource.recursive)
          end
        end
        new_resource.unscrubbed_values.each do |value|
          unless @name_hash.key?(value[:name].downcase)
            converge_by_value = value
            converge_by_value[:data] = "*sensitive value suppressed*" if new_resource.sensitive

            converge_by("create value #{converge_by_value}") do
              registry.set_value(new_resource.key, value)
            end
          end
        end
      end

      def action_delete
        if registry.key_exists?(new_resource.key)
          new_resource.unscrubbed_values.each do |value|
            if @name_hash.key?(value[:name].downcase)
              converge_by_value = value
              converge_by_value[:data] = "*sensitive value suppressed*" if new_resource.sensitive

              converge_by("delete value #{converge_by_value}") do
                registry.delete_value(new_resource.key, value)
              end
            end
          end
        end
      end

      def action_delete_key
        if registry.key_exists?(new_resource.key)
          converge_by("delete key #{new_resource.key}") do
            registry.delete_key(new_resource.key, new_resource.recursive)
          end
        end
      end

    end
  end
end
