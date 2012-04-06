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

      def set_all
        set_owner
        set_group
        set_mode unless resource.instance_of?(Chef::Resource::Link)
      end

      def requires_changes?
        should_update_mode? || should_update_owner? || should_update_group?
      end

      def describe_changes
        changes = []
        changes << "would change mode from '0#{current_mode.to_s(8)}' to '0#{target_mode.to_s(8)}'" if should_update_mode?
        changes << "would change owner from '#{current_resource.owner}' to '#{resource.owner}'" if should_update_owner?
        changes << "would change group from '#{current_resource.group}' to '#{resource.group}'" if should_update_group?
        changes
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
        return nil if resource.owner.nil?
        if resource.owner.kind_of?(String)
          diminished_radix_complement( Etc.getpwnam(resource.owner).uid )
        elsif resource.owner.kind_of?(Integer)
          resource.owner
        else
          Chef::Log.error("The `owner` parameter of the #@resource resource is set to an invalid value (#{resource.owner.inspect})")
          raise ArgumentError, "cannot resolve #{resource.owner.inspect} to uid, owner must be a string or integer"
        end
      rescue ArgumentError
        raise Chef::Exceptions::UserIDNotFound, "cannot determine user id for '#{resource.owner}', does the user exist on this system?"
      end

      def target_uid
        uid_from_resource(resource)
      end

      def current_uid
        uid_from_resource(current_resource)
      end

      def should_update_owner?
        target_uid != current_uid
      end

      def set_owner
        if should_update_owner?
          chown(target_uid, nil, file)
          Chef::Log.info("#{log_string} owner changed to #{target_uid}")
          modified
        end
      end

      def target_gid
        gid_from_resource(resource)
      end

      def current_gid
        gid_from_resource(current_resource)
      end

      def gid_from_resource(resource)
        return nil if resource.group.nil?
        if resource.group.kind_of?(String)
          diminished_radix_complement( Etc.getgrnam(resource.group).gid )
        elsif resource.group.kind_of?(Integer)
          resource.group
        else
          Chef::Log.error("The `group` parameter of the #@resource resource is set to an invalid value (#{resource.owner.inspect})")
          raise ArgumentError, "cannot resolve #{resource.group.inspect} to gid, group must be a string or integer"
        end
      rescue ArgumentError
        raise Chef::Exceptions::GroupIDNotFound, "cannot determine group id for '#{resource.group}', does the group exist on this system?"
      end

      def should_update_group?
        target_gid != current_gid
      end

      def set_group
        if should_update_group?
          chown(nil, target_gid, file)
          Chef::Log.info("#{log_string} group changed to #{target_gid}")
          modified
        end
      end

      def mode_from_resource(res)
        return nil if res.mode.nil?
        (res.mode.respond_to?(:oct) ? res.mode.oct : res.mode.to_i) & 007777
      end
      # TODO rename this to a more generic target_permissions
      def target_mode
        mode_from_resource(resource)
      end

      def current_mode
        mode_from_resource(current_resource)
      end

      def should_update_mode?
        current_mode != target_mode
      end

      # TODO rename this to a more generic set_permissions
      def set_mode
        if should_update_mode?
          File.chmod(target_mode, file)
          Chef::Log.info("#{log_string} mode changed to #{target_mode.to_s(8)}")

          modified
        end
      end

      def stat
        @stat ||= ::File.stat(file)
      end

      private
      def chown(uid, gid, file)
        if resource.instance_of?(Chef::Resource::Link)
          File.lchown(uid, gid, file)
        else
          File.chown(uid, gid, file)
        end
      end
    end
  end
end
