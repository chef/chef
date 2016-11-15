#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Daniel DeLeo (<dan@chef.io>)
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

require "chef/log"

class Chef
  class FileAccessControl
    module Unix
      UINT = (1 << 32)
      UID_MAX = (1 << 32) - 10

      module ClassMethods
        # We want to mix these in as class methods
        def writable?(path)
          ::File.writable?(path)
        end
      end

      def self.included(base)
        # When this file is mixed in, make sure we also add the class methods
        base.send :extend, ClassMethods
      end

      def set_all!
        set_owner!
        set_group!
        set_mode!
      end

      def set_all
        set_owner
        set_group
        set_mode
      end

      # TODO factor this up
      def requires_changes?
        should_update_mode? || should_update_owner? || should_update_group?
      end

      def define_resource_requirements
        uid_from_resource(resource)
        gid_from_resource(resource)
      end

      def describe_changes
        changes = []
        changes << "change mode from '#{mode_to_s(current_mode)}' to '#{mode_to_s(target_mode)}'" if should_update_mode?
        changes << "change owner from '#{current_resource.owner}' to '#{resource.owner}'" if should_update_owner?
        changes << "change group from '#{current_resource.group}' to '#{resource.group}'" if should_update_group?
        changes
      end

      def target_uid
        uid_from_resource(resource)
      end

      def current_uid
        uid_from_resource(current_resource)
      end

      def should_update_owner?
        if target_uid.nil?
          # the user has not specified a permission on the new resource, so we never manage it with FAC
          Chef::Log.debug("Found target_uid == nil, so no owner was specified on resource, not managing owner")
          return false
        elsif current_uid.nil?
          # the user has specified a permission, and we are creating a file, so always enforce permissions
          Chef::Log.debug("Found current_uid == nil, so we are creating a new file, updating owner")
          return true
        elsif target_uid != current_uid
          # the user has specified a permission, and it does not match the file, so fix the permission
          Chef::Log.debug("Found target_uid != current_uid, updating owner")
          return true
        else
          Chef::Log.debug("Found target_uid == current_uid, not updating owner")
          # the user has specified a permission, but it matches the file, so behave idempotently
          return false
        end
      end

      def set_owner!
        unless target_uid.nil?
          chown(target_uid, nil, file)
          Chef::Log.info("#{log_string} owner changed to #{target_uid}")
          modified
        end
      end

      def set_owner
        set_owner! if should_update_owner?
      end

      def target_gid
        gid_from_resource(resource)
      end

      def current_gid
        gid_from_resource(current_resource)
      end

      def gid_from_resource(resource)
        return nil if resource == nil || resource.group.nil?
        if resource.group.kind_of?(String)
          diminished_radix_complement( Etc.getgrnam(resource.group).gid )
        elsif resource.group.kind_of?(Integer)
          resource.group
        else
          Chef::Log.error("The `group` parameter of the #{@resource} resource is set to an invalid value (#{resource.owner.inspect})")
          raise ArgumentError, "cannot resolve #{resource.group.inspect} to gid, group must be a string or integer"
        end
      rescue ArgumentError
        provider.requirements.assert(:create, :create_if_missing, :touch) do |a|
          a.assertion { false }
          a.failure_message(Chef::Exceptions::GroupIDNotFound, "cannot determine group id for '#{resource.group}', does the group exist on this system?")
          a.whyrun("Assuming group #{resource.group} would have been created")
        end
        return nil
      end

      def should_update_group?
        if target_gid.nil?
          # the user has not specified a permission on the new resource, so we never manage it with FAC
          Chef::Log.debug("Found target_gid == nil, so no group was specified on resource, not managing group")
          return false
        elsif current_gid.nil?
          # the user has specified a permission, and we are creating a file, so always enforce permissions
          Chef::Log.debug("Found current_gid == nil, so we are creating a new file, updating group")
          return true
        elsif target_gid != current_gid
          # the user has specified a permission, and it does not match the file, so fix the permission
          Chef::Log.debug("Found target_gid != current_gid, updating group")
          return true
        else
          Chef::Log.debug("Found target_gid == current_gid, not updating group")
          # the user has specified a permission, but it matches the file, so behave idempotently
          return false
        end
      end

      def set_group!
        unless target_gid.nil?
          chown(nil, target_gid, file)
          Chef::Log.info("#{log_string} group changed to #{target_gid}")
          modified
        end
      end

      def set_group
        set_group! if should_update_group?
      end

      def mode_from_resource(res)
        return nil if res == nil || res.mode.nil?
        (res.mode.respond_to?(:oct) ? res.mode.oct : res.mode.to_i) & 007777
      end

      def target_mode
        mode_from_resource(resource)
      end

      def mode_to_s(mode)
        mode.nil? ? "" : "0#{mode.to_s(8)}"
      end

      def current_mode
        mode_from_resource(current_resource)
      end

      def should_update_mode?
        if target_mode.nil?
          # the user has not specified a permission on the new resource, so we never manage it with FAC
          Chef::Log.debug("Found target_mode == nil, so no mode was specified on resource, not managing mode")
          return false
        elsif current_mode.nil?
          # the user has specified a permission, and we are creating a file, so always enforce permissions
          Chef::Log.debug("Found current_mode == nil, so we are creating a new file, updating mode")
          return true
        elsif target_mode != current_mode
          # the user has specified a permission, and it does not match the file, so fix the permission
          Chef::Log.debug("Found target_mode != current_mode, updating mode")
          return true
        elsif suid_bit_set? && (should_update_group? || should_update_owner?)
          return true
        else
          Chef::Log.debug("Found target_mode == current_mode, not updating mode")
          # the user has specified a permission, but it matches the file, so behave idempotently
          return false
        end
      end

      def set_mode!
        unless target_mode.nil?
          chmod(target_mode, file)
          Chef::Log.info("#{log_string} mode changed to #{target_mode.to_s(8)}")
          modified
        end
      end

      def set_mode
        set_mode! if should_update_mode?
      end

      def stat
        if manage_symlink_attrs?
          @stat ||= File.lstat(file)
        else
          @stat ||= File.stat(file)
        end
      end

      def manage_symlink_attrs?
        @provider.manage_symlink_access?
      end

      private

      def chmod(mode, file)
        if manage_symlink_attrs?
          begin
            File.lchmod(mode, file)
          rescue NotImplementedError
            Chef::Log.warn("#{file} mode not changed: File.lchmod is unimplemented on this OS and Ruby version")
          end
        else
          File.chmod(mode, file)
        end
      end

      def chown(uid, gid, file)
        if manage_symlink_attrs?
          File.lchown(uid, gid, file)
        else
          File.chown(uid, gid, file)
        end
      end

      # Workaround the fact that Ruby's Etc module doesn't believe in negative
      # uids, so negative uids show up as the diminished radix complement of
      # a uint. For example, a uid of -2 is reported as 4294967294
      def diminished_radix_complement(int)
        if int > UID_MAX
          int - UINT
        else
          int
        end
      end

      def uid_from_resource(resource)
        return nil if resource == nil || resource.owner.nil?
        if resource.owner.kind_of?(String)
          diminished_radix_complement( Etc.getpwnam(resource.owner).uid )
        elsif resource.owner.kind_of?(Integer)
          resource.owner
        else
          Chef::Log.error("The `owner` parameter of the #{@resource} resource is set to an invalid value (#{resource.owner.inspect})")
          raise ArgumentError, "cannot resolve #{resource.owner.inspect} to uid, owner must be a string or integer"
        end
      rescue ArgumentError
        provider.requirements.assert(:create, :create_if_missing, :touch) do |a|
          a.assertion { false }
          a.failure_message(Chef::Exceptions::UserIDNotFound, "cannot determine user id for '#{resource.owner}', does the user exist on this system?")
          a.whyrun("Assuming user #{resource.owner} would have been created")
        end
        return nil
      end

      def suid_bit_set?
        return target_mode & 04000 > 0
      end
    end
  end
end
