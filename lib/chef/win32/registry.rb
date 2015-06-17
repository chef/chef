#
# Author:: Prajakta Purohit (<prajakta@opscode.com>)
# Author:: Lamont Granquist (<lamont@opscode.com>)
#
# Copyright:: 2012, Opscode, Inc.
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
require 'chef/reserved_names'

if RUBY_PLATFORM =~ /mswin|mingw32|windows/
  require 'win32/registry'
  require 'win32/api'
end

class Chef
  class Win32
    class Registry

      attr_accessor :run_context
      attr_accessor :architecture

      def initialize(run_context=nil, user_architecture=:machine)
        @run_context = run_context
        self.architecture = user_architecture
      end

      def architecture=(user_architecture)
        @architecture = user_architecture.to_sym
        assert_architecture!
      end

      def get_values(key_path)
        hive, key = get_hive_and_key(key_path)
        key_exists!(key_path)
        values = hive.open(key, ::Win32::Registry::KEY_READ | registry_system_architecture) do |reg|
          reg.map { |name, type, data| {:name=>name, :type=>get_name_from_type(type), :data=>data} }
        end
      end

      def set_value(key_path, value)
        Chef::Log.debug("Updating value #{value[:name]} in registry key #{key_path} with type #{value[:type]} and data #{value[:data]}")
        key_exists!(key_path)
        hive, key = get_hive_and_key(key_path)
        if value_exists?(key_path, value)
          if data_exists?(key_path, value)
            Chef::Log.debug("Value #{value[:name]} in registry key #{key_path} already had those values, not updated")
            return false
          else
            hive.open(key, ::Win32::Registry::KEY_SET_VALUE | ::Win32::Registry::KEY_QUERY_VALUE | registry_system_architecture) do |reg|
              reg.write(value[:name], get_type_from_name(value[:type]), value[:data])
            end
            Chef::Log.debug("Value #{value[:name]} in registry key #{key_path} updated")
          end
        else
          hive.open(key, ::Win32::Registry::KEY_SET_VALUE | ::Win32::Registry::KEY_QUERY_VALUE | registry_system_architecture) do |reg|
            reg.write(value[:name], get_type_from_name(value[:type]), value[:data])
          end
          Chef::Log.debug("Value #{value[:name]} in registry key #{key_path} created")
        end
        true
      end

      def delete_value(key_path, value)
        Chef::Log.debug("Deleting value #{value[:name]} from registry key #{key_path}")
        if value_exists?(key_path, value)
          begin
            hive, key = get_hive_and_key(key_path)
          rescue Chef::Exceptions::Win32RegKeyMissing
            return true
          end
          hive.open(key, ::Win32::Registry::KEY_SET_VALUE | registry_system_architecture) do |reg|
            reg.delete_value(value[:name])
            Chef::Log.debug("Deleted value #{value[:name]} from registry key #{key_path}")
          end
        else
          Chef::Log.debug("Value #{value[:name]} in registry key #{key_path} does not exist, not updated")
        end
        true
      end

      def create_key(key_path, recursive)
        Chef::Log.debug("Creating registry key #{key_path}")
        if keys_missing?(key_path)
          if recursive == true
            Chef::Log.debug("Registry key #{key_path} has missing subkeys, and recursive specified, creating them....")
            create_missing(key_path)
          else
            raise Chef::Exceptions::Win32RegNoRecursive, "Registry key #{key_path} has missing subkeys, and recursive not specified"
          end
        end
        if key_exists?(key_path)
          Chef::Log.debug("Registry key #{key_path} already exists, doing nothing")
        else
          hive, key = get_hive_and_key(key_path)
          hive.create(key, ::Win32::Registry::KEY_WRITE | registry_system_architecture)
          Chef::Log.debug("Registry key #{key_path} created")
        end
        true
      end

      def delete_key(key_path, recursive)
        Chef::Log.debug("Deleting registry key #{key_path}")
        unless key_exists?(key_path)
          Chef::Log.debug("Registry key #{key_path}, does not exist, not deleting")
          return true
        end
        #key_path is in the form "HKLM\Software\Opscode" for example, extracting
        #hive = HKLM,
        #hive_namespace = ::Win32::Registry::HKEY_LOCAL_MACHINE
        hive = key_path.split("\\").shift
        hive_namespace, key_including_parent = get_hive_and_key(key_path)
        if has_subkeys?(key_path)
          if recursive == true
            subkeys = get_subkeys(key_path)
            subkeys.each do |key|
              keypath_to_check = hive+"\\"+key_including_parent+"\\"+key
              Chef::Log.debug("Deleting registry key #{key_path} recursively")
              delete_key(keypath_to_check, true)
            end
            delete_key_ex(hive_namespace, key_including_parent)
          else
            raise Chef::Exceptions::Win32RegNoRecursive, "Registry key #{key_path} has subkeys, and recursive not specified"
          end
        else
          delete_key_ex(hive_namespace, key_including_parent)
          return true
        end
        true
      end

      #Using the 'RegDeleteKeyEx' Windows API that correctly supports WOW64 systems (Win2003)
      #instead of the 'RegDeleteKey'
      def delete_key_ex(hive, key)
        regDeleteKeyEx = ::Win32::API.new('RegDeleteKeyEx', 'LPLL', 'L', 'advapi32')
        hive_num = hive.hkey - (1 << 32)
        regDeleteKeyEx.call(hive_num, key, ::Win32::Registry::KEY_WRITE | registry_system_architecture, 0)
      end

      def key_exists?(key_path)
        hive, key = get_hive_and_key(key_path)
        begin
          hive.open(key, ::Win32::Registry::KEY_READ | registry_system_architecture) do |current_key|
            return true
          end
        rescue ::Win32::Registry::Error => e
          return false
        end
      end

      def key_exists!(key_path)
        unless key_exists?(key_path)
          raise Chef::Exceptions::Win32RegKeyMissing, "Registry key #{key_path} does not exist"
        end
        true
      end

      def hive_exists?(key_path)
        begin
          hive, key = get_hive_and_key(key_path)
        rescue Chef::Exceptions::Win32RegHiveMissing => e
          return false
        end
        return true
      end

      def has_subkeys?(key_path)
        key_exists!(key_path)
        hive, key = get_hive_and_key(key_path)
        hive.open(key, ::Win32::Registry::KEY_READ | registry_system_architecture) do |reg|
          reg.each_key{ |key| return true }
        end
        return false
      end

      def get_subkeys(key_path)
        subkeys = []
        key_exists!(key_path)
        hive, key = get_hive_and_key(key_path)
        hive.open(key, ::Win32::Registry::KEY_READ | registry_system_architecture) do |reg|
          reg.each_key{ |current_key| subkeys << current_key }
        end
        return subkeys
      end

      # 32-bit chef clients running on 64-bit machines will default to reading the 64-bit registry
      def registry_system_architecture
        applied_arch = ( architecture == :machine ) ? machine_architecture : architecture
        ( applied_arch == :x86_64 ) ? 0x0100 : 0x0200
      end

      def value_exists?(key_path, value)
        key_exists!(key_path)
        hive, key = get_hive_and_key(key_path)
        hive.open(key, ::Win32::Registry::KEY_READ | registry_system_architecture) do |reg|
          return true if reg.any? {|val| safely_downcase(val) == safely_downcase(value[:name]) }
        end
        return false
      end

      def data_exists?(key_path, value)
        key_exists!(key_path)
        hive, key = get_hive_and_key(key_path)
        hive.open(key, ::Win32::Registry::KEY_READ | registry_system_architecture) do |reg|
          reg.each do |val_name, val_type, val_data|
            if safely_downcase(val_name) == safely_downcase(value[:name]) &&
              val_type == get_type_from_name(value[:type]) &&
              val_data == value[:data]
              return true
            end
          end
        end
        return false
      end

      def value_exists!(key_path, value)
        unless value_exists?(key_path, value)
          raise Chef::Exceptions::Win32RegValueMissing, "Registry key #{key_path} has no value named #{value[:name]}"
        end
        true
      end

      def data_exists!(key_path, value)
        unless data_exists?(key_path, value)
          raise Chef::Exceptions::Win32RegDataMissing, "Registry key #{key_path} has no value named #{value[:name]}, containing type #{value[:type]} and data #{value[:data]}"
        end
        true
      end

      def type_matches?(key_path, value)
        value_exists!(key_path, value)
        hive, key = get_hive_and_key(key_path)
        hive.open(key, ::Win32::Registry::KEY_READ | registry_system_architecture) do |reg|
          reg.each do |val_name, val_type|
            if val_name == value[:name]
              type_new = get_type_from_name(value[:type])
              if val_type == type_new
                return true
              end
            end
          end
        end
        return false
      end

      def type_matches!(key_path, value)
        unless type_matches?(key_path, value)
          raise Chef::Exceptions::Win32RegTypesMismatch, "Registry key #{key_path} has a value #{value[:name]} with a type that is not #{value[:type]}"
        end
      end

      def get_type_from_name(val_type)
        value = {
          :binary => ::Win32::Registry::REG_BINARY,
          :string => ::Win32::Registry::REG_SZ,
          :multi_string => ::Win32::Registry::REG_MULTI_SZ,
          :expand_string => ::Win32::Registry::REG_EXPAND_SZ,
          :dword => ::Win32::Registry::REG_DWORD,
          :dword_big_endian => ::Win32::Registry::REG_DWORD_BIG_ENDIAN,
          :qword => ::Win32::Registry::REG_QWORD
        }[val_type]
        return value
      end

      def keys_missing?(key_path)
        missing_key_arr = key_path.split("\\")
        missing_key_arr.pop
        key = missing_key_arr.join("\\")
        !key_exists?(key)
      end

      def get_type_from_name(val_type)
        _type_name_map[val_type]
      end

      def get_name_from_type(val_class)
        _name_type_map[val_class]
      end

      private


      def safely_downcase(val)
        if val.is_a? String
          return val.downcase
        end
        return val
      end

      def node
        run_context && run_context.node
      end

      def machine_architecture
        node[:kernel][:machine].to_sym
      end

      def assert_architecture!
        if machine_architecture == :i386 && architecture == :x86_64
          raise Chef::Exceptions::Win32RegArchitectureIncorrect, "cannot access 64-bit registry on a 32-bit windows instance"
        end
      end

      def get_hive_and_key(path)
        reg_path = path.split("\\")
        hive_name = reg_path.shift
        key = reg_path.join("\\")

        hive = {
          "HKLM" => ::Win32::Registry::HKEY_LOCAL_MACHINE,
          "HKEY_LOCAL_MACHINE" => ::Win32::Registry::HKEY_LOCAL_MACHINE,
          "HKU" => ::Win32::Registry::HKEY_USERS,
          "HKEY_USERS" => ::Win32::Registry::HKEY_USERS,
          "HKCU" => ::Win32::Registry::HKEY_CURRENT_USER,
          "HKEY_CURRENT_USER" => ::Win32::Registry::HKEY_CURRENT_USER,
          "HKCR" => ::Win32::Registry::HKEY_CLASSES_ROOT,
          "HKEY_CLASSES_ROOT" => ::Win32::Registry::HKEY_CLASSES_ROOT,
          "HKCC" => ::Win32::Registry::HKEY_CURRENT_CONFIG,
          "HKEY_CURRENT_CONFIG" => ::Win32::Registry::HKEY_CURRENT_CONFIG,
        }[hive_name]

        raise Chef::Exceptions::Win32RegHiveMissing, "Registry Hive #{hive_name} does not exist" unless hive

        return hive, key
      end

      def _type_name_map
        {
          :binary => ::Win32::Registry::REG_BINARY,
          :string => ::Win32::Registry::REG_SZ,
          :multi_string => ::Win32::Registry::REG_MULTI_SZ,
          :expand_string => ::Win32::Registry::REG_EXPAND_SZ,
          :dword => ::Win32::Registry::REG_DWORD,
          :dword_big_endian => ::Win32::Registry::REG_DWORD_BIG_ENDIAN,
          :qword => ::Win32::Registry::REG_QWORD
        }
      end

      def _name_type_map
        @_name_type_map ||= _type_name_map.invert
      end

      def get_type_from_num(val_type)
        value = {
          3 => ::Win32::Registry::REG_BINARY,
          1 => ::Win32::Registry::REG_SZ,
          7 => ::Win32::Registry::REG_MULTI_SZ,
          2 => ::Win32::Registry::REG_EXPAND_SZ,
          4 => ::Win32::Registry::REG_DWORD,
          5 => ::Win32::Registry::REG_DWORD_BIG_ENDIAN,
          11 => ::Win32::Registry::REG_QWORD
        }[val_type]
        return value
      end

      def create_missing(key_path)
        missing_key_arr = key_path.split("\\")
        hivename = missing_key_arr.shift
        missing_key_arr.pop
        existing_key_path = hivename
        hive, key = get_hive_and_key(key_path)
        missing_key_arr.each do |intermediate_key|
          existing_key_path = existing_key_path << "\\" << intermediate_key
          if !key_exists?(existing_key_path)
            Chef::Log.debug("Recursively creating registry key #{existing_key_path}")
            hive.create(get_key(existing_key_path), ::Win32::Registry::KEY_ALL_ACCESS | registry_system_architecture)
          end
        end
      end

      def get_key(path)
        reg_path = path.split("\\")
        hive_name = reg_path.shift
        key = reg_path.join("\\")
      end

    end
  end
end
