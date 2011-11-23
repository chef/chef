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

      def set_all
        set_owner
        set_group
        set_dacl
      end

      private

      # Compare the actual ACL on a resource with the ACL we want.  This
      # ignores explicit ACLs on the target, and does mask prediction (if you
      # set GENERIC_WRITE, Windows will flip on a whole bunch of other rights
      # on the file when you save the ACL)
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

      def existing_descriptor
        securable_object.security_descriptor
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

      def securable_object
        @securable_object ||= begin
          if file.kind_of?(String)
            so = Chef::Win32::Security::SecurableObject.new(file.dup)
          end
          raise ArgumentError, "'file' must be a valid path or object of type 'Chef::Win32::Security::SecurableObject'" unless so.kind_of? Chef::Win32::Security::SecurableObject
          so
        end
      end

      def set_dacl
        dacl = target_dacl
        existing_dacl = existing_descriptor.dacl
        inherits = target_inherits
        if ! inherits.nil? && inherits != existing_descriptor.dacl_inherits?
          # We have to set DACL along with inherits.  If rights were not
          # specified, we need to change only inherited ACLs and leave
          # explicit ACLs alone.
          if dacl.nil? && !existing_dacl.nil?
            dacl = Chef::Win32::Security::ACL.create(existing_dacl.select { |ace| puts "ACE #{ace}"; !ace.inherited? })
          end
          securable_object.set_dacl(dacl, inherits)
          Chef::Log.info("#{log_string} permissions changed to #{dacl} with inherits of #{inherits}")
          modified
        elsif dacl && !acls_equal(dacl, existing_dacl)
          securable_object.dacl = dacl
          Chef::Log.info("#{log_string} permissions changed to #{dacl}")
          modified
        end
      end

      def set_group
        if (group = target_group) && (group != existing_descriptor.group)
          Chef::Log.info("#{log_string} group changed to #{gid}")
          securable_object.group = group
          modified
        end
      end

      def set_owner
        if (owner = target_owner) && (owner != existing_descriptor.owner)
          Chef::Log.info("#{log_string} owner changed to #{uid}")
          securable_object.owner = owner
          modified
        end
      end

      def target_dacl
        return nil if resource.rights.nil?

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

      def target_group
        return nil if resource.group.nil?
        sid = get_sid(resource.group)
      end

      def target_inherits
        resource.inherits
      end

      def target_owner
        return nil if resource.owner.nil?
        sid = get_sid(resource.owner)
      end
    end
  end
end
