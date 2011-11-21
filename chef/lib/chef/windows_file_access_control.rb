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

    def self.apply_security_policy(resource, securable_object)
      provider = WindowsFileAccessControl.new(resource, securable_object)
      provider.apply_security_policy()
    end

    def apply_security_policy
      modified = false

      existing = securable_object.security_descriptor
      # Apply owner and group
      if existing.owner != target_owner
        Chef::Log.info("Changing owner from #{existing.owner.account_name} to #{target_owner.account_name}")
        securable_object.owner = target_owner
        modified = true
      end
      if existing.group != target_group
        Chef::Log.info("Changing group from #{existing.group.account_name} to #{target_group.account_name}")
        securable_object.group = target_group
        modified = true
      end

      # Apply DACL and inherits
      target_dacl = build_target_dacl
      if existing.dacl_inherits? != target_inherits
        Chef::Log.info("Changing DACL and inherits")
        securable_object.set_dacl(target_dacl, target_inherits)
        modified = true
      elsif !acls_equal(target_dacl, existing.dacl)
        Chef::Log.info("Changing DACL")
        securable_object.dacl = target_dacl
        modified = true
      end

      modified
    end

    private

    def initialize(resource, securable_object)
      @resource = resource
      @securable_object = securable_object
    end
    
    attr_reader :resource
    attr_reader :securable_object

    Security = Chef::Win32::Security
    ACE = Security::ACE

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
      acls = []
      resource.rights.each_pair do |type, users|
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

    def get_sid(value)
      if value.kind_of?(String)
        Chef::Win32::Security::SID.from_account(value)
      elsif value.kind_of?(Chef::Win32::Security::SID)
        value
      else
        raise "Must specify username, group or SID: #{value}"
      end
    end
  end
end