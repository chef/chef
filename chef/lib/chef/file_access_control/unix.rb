#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2008-2011 Opscode, Inc.
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

class Chef
  class FileAccessControl
    module Unix
      UINT = (1 << 32)
      UID_MAX = (1 << 32) - 10

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
        !target_uid.nil? && target_uid != current_uid
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
        return nil if resource == nil or resource.group.nil?
        if resource.group.kind_of?(String)
          diminished_radix_complement( Etc.getgrnam(resource.group).gid )
        elsif resource.group.kind_of?(Integer)
          resource.group
        else
          Chef::Log.error("The `group` parameter of the #@resource resource is set to an invalid value (#{resource.owner.inspect})")
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
        !target_gid.nil? && target_gid != current_gid
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
        return nil if res == nil or res.mode.nil?
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
        !target_mode.nil? && current_mode != target_mode 
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
        if File.symlink?(file)
          @stat ||= File.lstat(file)
        else
          @stat ||= File.stat(file)
        end
      end

      private

      def chmod(mode, file)
        if File.symlink?(file)
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
        if ::File.symlink?(file)
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
        return nil if resource == nil or resource.owner.nil?
        if resource.owner.kind_of?(String)
          diminished_radix_complement( Etc.getpwnam(resource.owner).uid )
        elsif resource.owner.kind_of?(Integer)
          resource.owner
        else
          Chef::Log.error("The `owner` parameter of the #@resource resource is set to an invalid value (#{resource.owner.inspect})")
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

    end
  end
end
