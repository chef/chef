#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
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

require 'chef/win32/security'

class Chef
  class FileAccessControl
    module Windows
      include Chef::Win32::API::Security

      Security = Chef::Win32::Security
      ACE = Security::ACE

      def target_uid
        # TODO: make sure resource is tagged with the current user as the owner
        return nil if resource.owner.nil?
        sid = get_sid(resource.owner)
        sid.account_name if sid
      end

      def set_owner
        # Apply owner and group
        if (uid = target_uid) && (owner != existing_descriptor.owner)
          Chef::Log.info("#{log_string} owner changed to #{uid}")
          securable_object.owner = target_owner
          modified
        end
      end

      def target_gid
        if resource.group == nil
          # TODO: use well-known SIDs for this.  It appears to default to the "Domain Users" well-known SID.
          sid = get_sid("None")
        else
          sid = get_sid(resource.group)
        end
        sid.account_name if sid
      end

      def set_group
        if (gid = target_gid) && (gid != existing_descriptor.group)
          Chef::Log.info("#{log_string} group changed to #{gid}")
          securable_object.group = gid
          modified
        end
      end

      # TODO rename this to a more generic target_permissions
      def target_mode
        return nil if resource.rights.nil?
        build_target_dacl
      end

      # TODO rename this to a more generic set_permissions
      def set_mode
        # Apply DACL and inherits
        if (permissions = target_mode)
          if existing_descriptor.dacl_inherits? != target_inherits
            securable_object.set_dacl(permissions, target_inherits)
            Chef::Log.info("#{log_string} permissions changed to #{permissions} with inherits of #{target_inherits}")
            modified
          elsif !acls_equal(permissions, existing_descriptor.dacl)
            securable_object.dacl = permissions
            Chef::Log.info("#{log_string} permissions changed to #{permissions}")
            modified
          end
        end
      end

      def target_inherits
        resource.inherits == nil ? true : resource.inherits
      end

      private

      def get_sid(value)
        if value.kind_of?(String)
          Chef::Win32::Security::SID.from_account(value)
        elsif value.kind_of?(Chef::Win32::Security::SID)
          value
        else
          raise "Must specify username, group or SID: #{value}"
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

      def existing_descriptor
        securable_object.security_descriptor
      end

      def securable_object
        @securable_object ||= begin
          if file.kind_of?(String)
            so = Chef::Win32::Security::SecurableObject.new(file.dup)
          end
          # TODO this argument error message sucks
          raise ArgumentError, "'file' must be a valid path or object of type 'Chef::Win32::Security::SecurableObject'" unless so.kind_of? Chef::Win32::Security::SecurableObject
          so
        end
      end
    end
  end
end
