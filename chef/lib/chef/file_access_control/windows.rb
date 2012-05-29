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
      include Chef::ReservedNames::Win32::API::Security

      Security = Chef::ReservedNames::Win32::Security
      ACL = Security::ACL
      ACE = Security::ACE
      SID = Security::SID

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
        if actual_acl.nil?
          return target_acl.nil?
        end

        actual_acl = actual_acl.select { |ace| !ace.inherited? }
        # When ACLs apply to children, Windows splits them on the file system into two ACLs:
        # one specific applying to this container, and one generic applying to children.
        new_target_acl = []
        target_acl.each do |target_ace|
          if target_ace.flags & INHERIT_ONLY_ACE == 0
            self_ace = target_ace.dup
            self_ace.flags = 0
            self_ace.mask = securable_object.predict_rights_mask(target_ace.mask)
            new_target_acl << self_ace
          end
          if target_ace.flags & (CONTAINER_INHERIT_ACE | OBJECT_INHERIT_ACE) != 0
            children_ace = target_ace.dup
            children_ace.flags |= INHERIT_ONLY_ACE
            new_target_acl << children_ace
          end
        end
        return actual_acl == new_target_acl
      end

      def existing_descriptor
        securable_object.security_descriptor
      end

      def get_sid(value)
        if value.kind_of?(String)
          SID.from_account(value)
        elsif value.kind_of?(SID)
          value
        else
          raise "Must specify username, group or SID: #{value}"
        end
      end

      def securable_object
        @securable_object ||= begin
          if file.kind_of?(String)
            so = Chef::ReservedNames::Win32::Security::SecurableObject.new(file.dup)
          end
          raise ArgumentError, "'file' must be a valid path or object of type 'Chef::ReservedNames::Win32::Security::SecurableObject'" unless so.kind_of? Chef::ReservedNames::Win32::Security::SecurableObject
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
            dacl = ACL.create(existing_dacl.select { |ace| !ace.inherited? })
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
          Chef::Log.info("#{log_string} group changed to #{group}")
          securable_object.group = group
          modified
        end
      end

      def set_owner
        if (owner = target_owner) && (owner != existing_descriptor.owner)
          Chef::Log.info("#{log_string} owner changed to #{owner}")
          securable_object.owner = owner
          modified
        end
      end

      def mode_ace(sid, mode)
        mask = 0
        mask |= GENERIC_READ if mode & 4 != 0
        mask |= (GENERIC_WRITE | DELETE) if mode & 2 != 0
        mask |= GENERIC_EXECUTE if mode & 1 != 0
        return [] if mask == 0
        [ ACE.access_allowed(sid, mask) ]
      end

      def calculate_mask(permissions)
        mask = 0
        [ permissions ].flatten.each do |permission|
          case permission
          when :full_control
            mask |= GENERIC_ALL
          when :modify
            mask |= GENERIC_WRITE | GENERIC_READ | GENERIC_EXECUTE | DELETE
          when :read
            mask |= GENERIC_READ
          when :read_execute
            mask |= GENERIC_READ | GENERIC_EXECUTE
          when :write
            mask |= GENERIC_WRITE
          else
            # Otherwise, assume it's an integer specifying the actual flags
            mask |= permission
          end
        end
        mask
      end

      def calculate_flags(rights)
        # Handle inheritance flags
        flags = 0
        case rights[:applies_to_children]
        when :containers_only
          flags |= CONTAINER_INHERIT_ACE
        when :objects_only
          flags |= OBJECT_INHERIT_ACE
        when true
          flags |= CONTAINER_INHERIT_ACE
          flags |= OBJECT_INHERIT_ACE
        when nil
          flags |= CONTAINER_INHERIT_ACE
          flags |= OBJECT_INHERIT_ACE
        end

        if rights[:applies_to_self] == false
          flags |= INHERIT_ONLY_ACE
        end

        if rights[:one_level_deep]
          flags |= NO_PROPAGATE_INHERIT_ACE
        end
        flags
      end

      def target_dacl
        return nil if resource.rights.nil? && resource.deny_rights.nil? && resource.mode.nil?
        acls = nil

        if !resource.deny_rights.nil?
          acls = [] if acls.nil?

          resource.deny_rights.each do |rights|
            mask = calculate_mask(rights[:permissions])
            [ rights[:principals] ].flatten.each do |principal|
              sid = get_sid(principal)
              flags = calculate_flags(rights)
              acls.push ACE.access_denied(sid, mask, flags)
            end
          end
        end

        if !resource.rights.nil?
          acls = [] if acls.nil?

          resource.rights.each do |rights|
            mask = calculate_mask(rights[:permissions])
            [ rights[:principals] ].flatten.each do |principal|
              sid = get_sid(principal)
              flags = calculate_flags(rights)
              acls.push ACE.access_allowed(sid, mask, flags)
            end
          end
        end

        if !resource.mode.nil?
          acls = [] if acls.nil?

          mode = (resource.mode.respond_to?(:oct) ? resource.mode.oct : resource.mode.to_i) & 0777

          owner = target_owner
          if owner
            acls += mode_ace(owner, (mode & 0700) >> 6)
          elsif mode & 0700 != 0
            Chef::Log.warn("Mode #{sprintf("%03o", mode)} includes bits for the owner, but owner is not specified")
          end

          group = target_group
          if group
            acls += mode_ace(group, (mode & 070) >> 3)
          elsif mode & 070 != 0
            Chef::Log.warn("Mode #{sprintf("%03o", mode)} includes bits for the group, but group is not specified")
          end

          acls += mode_ace(SID.Everyone, (mode & 07))
        end

        acls.nil? ? nil : Chef::ReservedNames::Win32::Security::ACL.create(acls)
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
