#
# Author:: Doug MacEachern (<dougm@vmware.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Author:: Paul Morton (<pmorton@biaprotect.com>)
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
require 'chef/reserved_names'

if RUBY_PLATFORM =~ /mswin|mingw32|windows/
  require 'win32/registry'
  require 'ruby-wmi'
end
class Chef
  class Win32
    class Registry
      attr_accessor :run_context

      def initialize(run_context=nil)
        @run_context = run_context
      end

      def node
        run_context && run_context.node
      end

      def get_values(key_path, architecture)
        if architecture_correct?(architecture)
          key = get_key(key_path)
          hive = get_hive(key_path)
          if key_exists?(key_path, architecture)
            values = []
            hive.open(key) do |reg|
              reg.each do |name, type, data| 
                value={:name=>name, :type=>type, :data=>data}
                values << value
              end
            end
            return values
          end
        end
        return false
      end

      def update_value(key_path, value, architecture)
        if value_exists?(key_path, value, architecture)
          if type_matches?(key_path, value, architecture)
            hive = get_hive(key_path)
            key = get_key(key_path)
            hive.open(key, ::Win32::Registry::KEY_ALL_ACCESS) do |reg|
              reg.each{|name, type, data|
                if value[:name] == name
                  if data != value[:data]
                    reg.write(value[:name], get_type_from_name(value[:type]), value[:data])
                    return true
                  else
                    puts "Data is the same not updated"
                    return "no_action"
                  end
                else
                  puts "Value does not exist --- check if we want to include create_if_missing here"
                  return false
                end
              }
            end
          else
            puts "Types do not match"
            return false
          end
        else
          puts "Value does not exist -- it could be key does not exist"
          return false
        end
      end

      def create_value(key_path, value, architecture)
        hive = get_hive(key_path)
        if !value_exists?(key_path, value, architecture)
          key = get_key(key_path)
          hive.open(key, ::Win32::Registry::KEY_ALL_ACCESS) do |reg|
              reg.write(value[:name], get_type_from_name(value[:type]), value[:data])
          end
        else
          puts "Value exists not checking for the type or data"
        end
      end

      def create_key(key_path, value, architecture, recursive)
        hive = get_hive(key_path)
        if architecture_correct?(architecture)
          if keys_missing?(key_path, architecture)
            if recursive == true
              create_missing(key_path, architecture)
              key = get_key(key_path)
              hive.create key
              create_value(key_path, value, architecture)
              return true
            end
          else
            hive.create key_path
            create_value(key_path, value, architecture)
            return true
          end
        end
        return false
      end

      def delete_value(key_path, value, architecture)
        hive = get_hive(key_path)
        if architecture_correct?(architecture)
          if key_exists?(key_path, architecture)
            key = get_key(key_path)
            hive.open(key, ::Win32::Registry::KEY_ALL_ACCESS) do |reg|
              reg.delete_value(value[:name])
            end
          end
        end
      end

      def delete_key(key_path, value, architecture, recursive)
        hive = get_hive(key_path)
        key = get_key(key_path)
        key_parent = key.split("\\")
        key_to_delete = key_parent.pop
        key_parent = key_parent.join("\\")
        if architecture_correct?(architecture)
          if key_exists?(key_path, architecture)
            if has_subkeys(key_path, architecture)
              if recursive == true
                hive.open(key_parent, ::Win32::Registry::KEY_WRITE) do |reg|
                  reg.delete_key(key_to_delete,true)
                end
              end
            else
              hive.open(key_parent, ::Win32::Registry::KEY_WRITE) do |reg|
                reg.delete_key(key_to_delete)
              end
            end
          end
        end
      end

      def has_subkeys(key_path, architecture)
        hive = get_hive(key_path)
        subkeys = nil
        if architecture_correct?(architecture)
          if key_exists?(key_path, architecture)
            key = get_key(key_path)
            hive.open(key) do |reg|
              reg.each_key{ |key|
                subkeys = key
              }
            end
          end
          if subkeys == nil
            puts "no subkeys"
            return false
          else
            puts "subkeys are #{subkeys}"
            return true
          end
        end
      end

      def get_subkeys(key_path, architecture)
        hive = get_hive(key_path)
        subkeys = []
        if architecture_correct?(architecture)
          if key_exists?(key_path, architecture)
            key = get_key(key_path)
            hive.open(key) do |reg|
              reg.each_key{ |key|
                subkeys << key
              }
            end
          end
          return subkeys
        end
      end

      def key_exists?(key_path, architecture)
        if architecture_correct?(architecture)
          if hive_exists?(key_path)
            hive = get_hive(key_path)
            key = get_key(key_path)
            begin
              hive.open(key, ::Win32::Registry::Constants::KEY_READ) do |key|
                @exists = true
              end
            rescue
              @exists = false
            end
          end
        end
        return @exists
      end

      def hive_exists?(key_path)
        hive = get_hive(key_path)
        Chef::Log.debug("Registry hive resolved to #{hive}")
        unless hive
          return false
        end
        return true
      end

      private

      def get_hive(path)
        Chef::Log.debug("Resolving registry shortcuts from path to full names")

        reg_path = path.split("\\")
        hive_name = reg_path.shift

        hive = {
          "HKLM" => ::Win32::Registry::HKEY_LOCAL_MACHINE,
          "HKU" => ::Win32::Registry::HKEY_USERS,
          "HKCU" => ::Win32::Registry::HKEY_CURRENT_USER,
          "HKCR" => ::Win32::Registry::HKEY_CLASSES_ROOT,
          "HKCC" => ::Win32::Registry::HKEY_CURRENT_CONFIG
        }[hive_name]

        #unless hive
        #  Chef::Application.fatal!("Unsupported registry hive '#{hive_name}'")
        #end
        return hive
      end

      def get_key(path)
        reg_path = path.split("\\")
        hive_name = reg_path.shift
        key = reg_path.join("\\")
        return key
      end

      def architecture_correct?(user_architecture)
      #  native_architecture = ENV['PROCESSOR_ARCHITEW6432']
        # Returns false if requesting for a 64but architecture on a 32 bit system
        system_architecture = node[:kernel][:machine]
        return true if system_architecture == "x86_64"
        return (user_architecture == "i386")
      #   return true
      end

      def value_exists?(key_path, value, architecture)
        if key_exists?(key_path, architecture)
          hive = get_hive(key_path)
          key = get_key(key_path)
          hive.open(key) do |reg|
            reg.each{|val_name|
              if val_name == value[:name]
                @exists = true
                return true
              end}
          end
        end
        return false
      end

      def type_matches?(key_path, value, architecture)
        if value_exists?(key_path, value, architecture)
          hive = get_hive(key_path)
          key = get_key(key_path)
          matches = false
          hive.open(key) do |reg|
            reg.each{|val_name, val_type|
              if val_name == value[:name]
             #   type_current = get_type_from_enum(val_type)
                type_new = get_type_from_name(value[:type])
                if val_type == type_new
                  matches = true
                end
              end
            }
          end
          return matches
        end
      end

#      def get_type_from_enum(val_type)
#        value = {
#          1 => ::Win32::Registry::REG_SZ,
#          2 => ::Win32::Registry::REG_EXPAND_SZ,
#          3 => ::Win32::Registry::REG_BINARY,
#          4 => ::Win32::Registry::REG_DWORD,
#          5 => ::Win32::Registry::REG_DWORD_BIG_ENDIAN,
#          7 => ::Win32::Registry::REG_MULTI_SZ,
#          11 => ::Win32::Registry::REG_QWORD
#        }[val_type]
#        return value
#      end

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

      def keys_missing?(missing_key_path, architecture)
        missing_key = get_key(missing_key_path)
        missing_key_arr = missing_key.split("\\")
        missing_key_arr.pop
        existing_key_path = ""
        keys_missing = true
        missing_key_arr.each do |intermediate_key| 
          existing_key_path = existing_key_path << "\\" << intermediate_key
          puts existing_key_path
          keys_missing = !key_exists?(existing_key_path, architecture)
          break unless keys_missing
        end
        return keys_missing
      end

      def keys_missing?(missing_key_path, architecture)
        missing_key = get_key(missing_key_path)
        missing_key_arr = missing_key.split("\\")
        missing_key_arr.pop
        key = missing_key_arr.join("\\")
        key_missing = key_exists?(key, architecture)
      end



      def create_missing(missing_key_path, architecture)
        missing_key = get_key(missing_key_path)
        missing_key_arr = missing_key.split("\\")
        missing_key_arr.pop
        existing_key_path = ""
        missing_key_arr.each do |intermediate_key| 
          existing_key_path = existing_key_path << "\\" << intermediate_key
          if !key_exists?(existing_key_path, architecture)
            hive = get_hive(missing_key_path)
            hive.create missing_key_path
          end
        end
      end

#      @@native_registry_constant = ENV['PROCESSOR_ARCHITEW6432'] == 'AMD64' ? 0x0100 : 0x0200
#
#      def get_hive_name(path)
#        Chef::Log.debug("Resolving registry shortcuts to full names")
#
#        reg_path = path.split("\\")
#        hive_name = reg_path.shift
#
#        hkey = {
#          "HKLM" => "HKEY_LOCAL_MACHINE",
#          "HKCU" => "HKEY_CURRENT_USER",
#          "HKU"  => "HKEY_USERS"
#        }[hive_name] || hive_name
#
#        Chef::Log.debug("Hive resolved to #{hkey}")
#        return hkey
#      end
#
#      def get_hive(path)
#
#        Chef::Log.debug("Getting hive for #{path}")
#        reg_path = path.split("\\")
#        hive_name = reg_path.shift
#
#        hkey = get_hive_name(path)
#
#        hive = {
#          "HKEY_LOCAL_MACHINE" => ::Win32::Registry::HKEY_LOCAL_MACHINE,
#          "HKEY_USERS" => ::Win32::Registry::HKEY_USERS,
#          "HKEY_CURRENT_USER" => ::Win32::Registry::HKEY_CURRENT_USER
#        }[hkey]
#
#        unless hive
#          Chef::Application.fatal!("Unsupported registry hive '#{hive_name}'")
#        end
#
#
#        Chef::Log.debug("Registry hive resolved to #{hkey}")
#        return hive
#      end
#
#      def unload_hive(path)
#        hive = get_hive(path)
#        if hive == ::Win32::Registry::HKEY_USERS
#          reg_path = path.split("\\")
#          priv = Chef::WindowsPrivileged.new
#          begin
#            priv.reg_unload_key(reg_path[1])
#          rescue
#          end
#        end
#      end
#
#      def set_value(mode,path,values,type=nil)
#        hive, reg_path, hive_name, root_key, hive_loaded = get_reg_path_info(path)
#        key_name = reg_path.join("\\")
#
#        puts "hive: #{hive}"
#        puts"-----------"
#        puts "reg_path: #{reg_path}"
#        puts"-----------"
#        puts "hive_name: #{hive_name}"
#        puts"-----------"
#        puts "root_key: #{root_key}"
#        puts"-----------"
#        puts "hive_loaded: #{hive_loaded}"
#        puts "----------"
#        puts "values: #{values}"
#        puts "----------"
#        puts "key_name:(reg_path.join) #{key_name}"
#        puts "----------"
#        puts "path: #{path}"
#        
#        Chef::Log.debug("Creating #{path}")
#
#        if !key_exists?(path,true)
#          create_key(path)
#        end
#
#        hive.send(mode, key_name, ::Win32::Registry::KEY_ALL_ACCESS | @@native_registry_constant) do |reg|
#          changed_something = false
#          values.each do |k,val|
#            key = "#{k}" #wtf. avoid "can't modify frozen string" in win32/registry.rb
#            cur_val = nil
#            begin
#              cur_val = reg[key]
#            rescue
#              #subkey does not exist (ok)
#            end
#            if cur_val != val
#              Chef::Log.debug("setting #{key}=#{val}")
#
#              if type.nil?
#                type = :string
#              end
#
#              reg_type = {
#                :binary => ::Win32::Registry::REG_BINARY,
#                :string => ::Win32::Registry::REG_SZ,
#                :multi_string => ::Win32::Registry::REG_MULTI_SZ,
#                :expand_string => ::Win32::Registry::REG_EXPAND_SZ,
#                :dword => ::Win32::Registry::REG_DWORD,
#                :dword_big_endian => ::Win32::Registry::REG_DWORD_BIG_ENDIAN,
#                :qword => ::Win32::Registry::REG_QWORD
#              }[type]
#
#              puts "reg: #{reg} key: #{key} reg_type: #{reg_type} val: #{val}"
#              reg.write(key, reg_type, val)
#
#              ensure_hive_unloaded(hive_loaded)
#
#              changed_something = true
#            end
#          end
#          return changed_something
#        end
#        return false
#      end
#
#      def get_value(path,value)
#        hive, reg_path, hive_name, root_key, hive_loaded = get_reg_path_info(path)
#        key = reg_path.join("\\")
#
#        hive.open(key, ::Win32::Registry::KEY_ALL_ACCESS | @@native_registry_constant) do | reg |
#          begin
#            puts reg[value]
#            return reg[value]
#        rescue
#          return nil
#        ensure
#          ensure_hive_unloaded(hive_loaded)
#        end
#        end
#      end
#
#      def get_values(path)
#        hive, reg_path, hive_name, root_key, hive_loaded = get_reg_path_info(path)
#        key = reg_path.join("\\")
#
#        hive.open(key, ::Win32::Registry::KEY_ALL_ACCESS | @@native_registry_constant) do | reg |
#          values = []
#        begin
#          reg.each_value do |name, type, data|
#            values << [name, type, data]
#          end
#        rescue
#        ensure
#          ensure_hive_unloaded(hive_loaded)
#        end
#        values
#        end
#      end
#
#      def delete_value(path,values)
#        hive, reg_path, hive_name, root_key, hive_loaded = get_reg_path_info(path)
#        key = reg_path.join("\\")
#        Chef::Log.debug("Deleting values in #{path}")
#        hive.open(key, ::Win32::Registry::KEY_ALL_ACCESS | @@native_registry_constant) do | reg |
#          values.each_key { |key|
#          name = "#{key}"
#          # Ensure delete operation is idempotent.
#          if value_exists?(path, key)
#            Chef::Log.debug("Deleting value #{name} in #{path}")
#            reg.delete_value(name)
#          else
#            Chef::Log.debug("Value #{name} in #{path} does not exist, skipping.")
#          end
#        }
#        end
#
#      end
#
#      def create_key(path)
#        hive, reg_path, hive_name, root_key, hive_loaded = get_reg_path_info(path)
#        key = reg_path.join("\\")
#        Chef::Log.debug("Creating registry key #{path}")
#        hive.create(key)
#      end
#
#      def value_exists?(path,value)
#        if key_exists?(path,true)
#
#          hive, reg_path, hive_name, root_key , hive_loaded = get_reg_path_info(path)
#          key = reg_path.join("\\")
#
#          Chef::Log.debug("Attempting to open #{key}");
#          Chef::Log.debug("Native Constant #{@@native_registry_constant}")
#          Chef::Log.debug("Hive #{hive}")
#
#          hive.open(key, ::Win32::Registry::KEY_READ | @@native_registry_constant) do | reg |
#            begin
#              rtn_value = reg[value]
#              return true
#          rescue
#            return false
#          ensure
#            ensure_hive_unloaded(hive_loaded)
#          end
#          end
#
#        end
#        return false
#      end
#
#      # TODO: Does not load user registry...
#      def key_exists?(path, load_hive = false)
#        if load_hive
#          hive, reg_path, hive_name, root_key , hive_loaded = get_reg_path_info(path)
#          key = reg_path.join("\\")
#        else
#          hive = get_hive(path)
#          reg_path = path.split("\\")
#          hive_name = reg_path.shift
#          root_key = reg_path[0]
#          key = reg_path.join("\\")
#          hive_loaded = false
#        end
#
#        begin
#          hive.open(key, ::Win32::Registry::Constants::KEY_READ | @@native_registry_constant )
#          return true
#        rescue
#          return false
#        ensure
#          ensure_hive_unloaded(hive_loaded)
#        end
#      end
#
#      def get_user_hive_location(sid)
#        reg_key = "HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\ProfileList\\#{sid}"
#        Chef::Log.debug("Looking for profile at #{reg_key}")
#        if key_exists?(reg_key)
#          return get_value(reg_key,'ProfileImagePath')
#        else
#          return nil
#        end
#
#      end
#
#      def resolve_user_to_sid(username)
#        begin
#          puts "uname #{username}"
#          sid = WMI::Win32_UserAccount.find(:first, :conditions => {:name => username}).sid
#          puts "sig ::::::::: #{sid}"
#          Chef::Log.debug("Resolved user SID to #{sid}")
#          return sid
#        rescue
#          puts "returning nil"
#          return nil
#        end
#      end
#
#      def hive_loaded?(path)
#        hive = get_hive(path)
#        reg_path = path.split("\\")
#        hive_name = reg_path.shift
#        user_hive = path[0]
#
#        if is_user_hive?(hive)
#          return key_exists?("#{hive_name}\\#{user_hive}")
#        else
#          return true
#        end
#      end
#
#      def is_user_hive?(hive)
#        if hive == ::Win32::Registry::HKEY_USERS
#          return true
#        else
#          return true
#        end
#      end
#
#      def get_reg_path_info(path)
#        hive = get_hive(path)
#        reg_path = path.split("\\")
#        hive_name = reg_path.shift
#        root_key = reg_path[0]
#        hive_loaded = false
#
#        if is_user_hive?(hive) && !key_exists?("#{hive_name}\\#{root_key}")
#          reg_path, hive_loaded = load_user_hive(hive,reg_path,root_key)
#          root_key = reg_path[0]
#          Chef::Log.debug("Resolved user (#{path}) to (#{reg_path.join('/')})")
#        end
#
#        return hive, reg_path, hive_name, root_key, hive_loaded
#      end
#
#      def load_user_hive(hive,reg_path,user_hive)
#        Chef::Log.debug("Reg Path #{reg_path}")
#        # See if the hive is loaded. Logged in users will have a key that is named their SID
#        # if the user has specified the a path by SID and the user is logged in, this function
#        # should not be executed.
#        if is_user_hive?(hive) && !key_exists?("HKU\\#{user_hive}")
#          Chef::Log.debug("The user is not logged in and has not been specified by SID")
#          sid = resolve_user_to_sid(user_hive)
#          puts "sid ***** #{sid} *************"
#          Chef::Log.debug("User SID resolved to (#{sid})")
#          # Now that the user has been resolved to a SID, check and see if the hive exists.
#          # If this exists by SID, the user is logged in and we should use that key.
#          # TODO: Replace the username with the sid and send it back because the username
#          # does not exist as the key location.
#          load_reg = false
#          if key_exists?("HKU\\#{sid}")
#            puts "in if"
#            reg_path[0] = sid #use the active profile (user is logged on)
#            Chef::Log.debug("HKEY_USERS Mapped: #{user_hive} -> #{sid}")
#          else
#            puts "in else"
#            Chef::Log.debug("User is not logged in")
#            load_reg = true
#          end
#
#          # The user is not logged in, so we should load the registry from disk
#          if load_reg
#            profile_path = get_user_hive_location(sid)
#            if profile_path != nil
#              ntuser_dat = "#{profile_path}\\NTUSER.DAT"
#              if ::File.exists?(ntuser_dat)
#                priv = Chef::WindowsPrivileged.new
#                if priv.reg_load_key(sid,ntuser_dat)
#                  Chef::Log.debug("RegLoadKey(#{sid}, #{user_hive}, #{ntuser_dat})")
#                  reg_path[0] = sid
#                else
#                  Chef::Log.debug("Failed RegLoadKey(#{sid}, #{user_hive}, #{ntuser_dat})")
#                end
#              end
#            end
#          end
#        end
#
#        return reg_path, load_reg
#
#      end
#
#      private
#      def ensure_hive_unloaded(hive_loaded=false)
#        if(hive_loaded)
#          Chef::Log.debug("Hive was loaded, we really should unload it")
#          unload_hive(path)
#        end
#      end
#      #  end
#      #end
    end
  end
end


#module Registry
#  module_function
#  extend Windows::RegistryHelper
#end
