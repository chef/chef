#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright 2011 Opscode, Inc.
# License:: Apache License, Version 2.0
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

require 'chef/log'
require 'chef/win32/security'

class Chef
  class WindowsFileAccessControl
    include Chef::Win32::API::Security

    def initialize(resource, securable_object)
      @resource = resource
      if securable_object.kind_of?(String)
        securable_object = Chef::Win32::Security::SecurableObject.new(securable_object.dup)
      end
      @securable_object = securable_object
      @existing_descriptor = securable_object.security_descriptor
      Chef::Log.warn("Existing security descriptor for [#{securable_object}] apears to be nil") unless @existing_descriptor
      @modified = false
    end

    attr_reader :resource
    attr_reader :securable_object
    attr_reader :existing_descriptor

    Security = Chef::Win32::Security
    ACE = Security::ACE

    def modified?
      @modified
    end

    def set_all
      set_owner
      set_group
      set_rights
    end

    def set_owner
      # Apply owner and group
      if (owner = target_owner) && (owner != existing_descriptor.owner)
        Chef::Log.info("Changing owner from #{existing_descriptor.owner.account_name} to #{target_owner.account_name}")
        securable_object.owner = target_owner
        modified
      end
    end

    def set_group
      if (group = target_group) && (group != existing_descriptor.group)
        Chef::Log.info("Changing group from #{existing_descriptor.group.account_name} to #{target_group.account_name}")
        securable_object.group = target_group
        modified
      end
    end

    def set_rights
      # Apply DACL and inherits
      if (target_dacl = build_target_dacl)
        if existing_descriptor.dacl_inherits? != target_inherits
          Chef::Log.info("Changing DACL and inherits")
          securable_object.set_dacl(target_dacl, target_inherits)
          modified
        elsif !acls_equal(target_dacl, existing_descriptor.dacl)
          Chef::Log.info("Changing DACL")
          securable_object.dacl = target_dacl
          modified
        end
      end
    end

    def acls_equal(target_acl, actual_acl)
      actual_acl = actual_acl.select { |ace| !ace.inherited? }
      return false if target_acl.length != actual_acl.length
      0.upto(target_acl.length - 1) do |i|
        target_ace = target_acl[i]
        actual_ace = actual_acl[i]
        return false if target_ace.sid != actual_ace.sid
        return false if target_ace.flags != actual_ace.flags
        return false if securable_object.predict_rights_mask(target_ace.mask) != actual_ace.mask
      end
    end

    def target_inherits
      resource.inherits == nil ? true : resource.inherits
    end

    def target_owner
      # TODO: make sure resource is tagged with the current user as the owner
      return nil if resource.owner.nil?
      get_sid(resource.owner)
    end

    def target_group
      if resource.group == nil
        # TODO: use well-known SIDs for this.  It appears to default to the "Domain Users" well-known SID.
        get_sid("None")
      else
        get_sid(resource.group)
      end
    end

    def build_target_dacl
      unless resource.rights.nil?
        acls = []
        resource.rights.each_pair do |type, users|
          users = [users] unless users.kind_of? Array
          case type
          when :deny
            users.each { |user| acls.push ACE.access_denied(get_sid(user), GENERIC_ALL) }
          when :read
            users.each { |user| acls.push(ACE.access_allowed(get_sid(user), GENERIC_READ | GENERIC_EXECUTE)) }
          when :write
            users.each { |user| acls.push(ACE.access_allowed(get_sid(user), GENERIC_WRITE | GENERIC_READ | GENERIC_EXECUTE)) }
          when :full
            users.each { |user| acls.push(ACE.access_allowed(get_sid(user), GENERIC_ALL)) }
          else
            raise "Unknown rights type #{type}"
          end
        end
        Chef::Win32::Security::ACL.create(acls)
      end
    end

    def get_sid(value)
      if value.kind_of?(String)
        Chef::Win32::Security::SID.from_account(value)
      elsif value.kind_of?(Chef::Win32::Security::SID)
        value
      else
        raise "Must specify username, group or SID: #{value}"
      end
    end

    private

    def modified
      @modified = true
    end
  end
end
