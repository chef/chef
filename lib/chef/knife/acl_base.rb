#
# Author:: Steven Danna (steve@chef.io)
# Author:: Jeremiah Snapp (<jeremiah@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../knife"

class Chef
  class Knife
    module AclBase

      PERM_TYPES = %w{create read update delete grant}.freeze unless defined? PERM_TYPES
      MEMBER_TYPES = %w{client group user}.freeze unless defined? MEMBER_TYPES
      OBJECT_TYPES = %w{clients containers cookbooks data environments groups nodes roles policies policy_groups}.freeze unless defined? OBJECT_TYPES
      OBJECT_NAME_SPEC = /^[\-[:alnum:]_\.]+$/.freeze unless defined? OBJECT_NAME_SPEC

      def validate_object_type!(type)
        unless OBJECT_TYPES.include?(type)
          ui.fatal "Unknown object type \"#{type}\".  The following types are permitted: #{OBJECT_TYPES.join(", ")}"
          exit 1
        end
      end

      def validate_object_name!(name)
        unless OBJECT_NAME_SPEC.match(name)
          ui.fatal "Invalid name: #{name}"
          exit 1
        end
      end

      def validate_member_type!(type)
        unless MEMBER_TYPES.include?(type)
          ui.fatal "Unknown member type \"#{type}\". The following types are permitted: #{MEMBER_TYPES.join(", ")}"
          exit 1
        end
      end

      def validate_member_name!(name)
        # Same rules apply to objects and members
        validate_object_name!(name)
      end

      def validate_perm_type!(perms)
        perms.split(",").each do |perm|
          unless PERM_TYPES.include?(perm)
            ui.fatal "Invalid permission \"#{perm}\". The following permissions are permitted: #{PERM_TYPES.join(",")}"
            exit 1
          end
        end
      end

      def validate_member_exists!(member_type, member_name)
        true if rest.get_rest("#{member_type}s/#{member_name}")
      rescue NameError
        # ignore "NameError: uninitialized constant Chef::ApiClient" when finding a client
        true
      rescue
        ui.fatal "#{member_type} '#{member_name}' does not exist"
        exit 1
      end

      def is_usag?(gname)
        gname.length == 32 && gname =~ /^[0-9a-f]+$/
      end

      def get_acl(object_type, object_name)
        rest.get_rest("#{object_type}/#{object_name}/_acl?detail=granular")
      end

      def get_ace(object_type, object_name, perm)
        get_acl(object_type, object_name)[perm]
      end

      def add_to_acl!(member_type, member_name, object_type, object_name, perms)
        acl = get_acl(object_type, object_name)
        perms.split(",").each do |perm|
          ui.msg "Adding '#{member_name}' to '#{perm}' ACE of '#{object_name}'"
          ace = acl[perm]

          case member_type
          when "client", "user"
            # Our PUT body depends on the type of reply we get from _acl?detail=granular
            # When the server replies with json attributes  'users' and 'clients',
            # we'll want to modify entries under the same keys they arrived.- their presence
            # in the body tells us that CS will accept them in a PUT.
            # Older version of chef-server will continue to use 'actors' for a combined list
            # and expect the same in the body.
            key = "#{member_type}s"
            key = "actors" unless ace.key? key
            next if ace[key].include?(member_name)

            ace[key] << member_name
          when "group"
            next if ace["groups"].include?(member_name)

            ace["groups"] << member_name
          end

          update_ace!(object_type, object_name, perm, ace)
        end
      end

      def remove_from_acl!(member_type, member_name, object_type, object_name, perms)
        acl = get_acl(object_type, object_name)
        perms.split(",").each do |perm|
          ui.msg "Removing '#{member_name}' from '#{perm}' ACE of '#{object_name}'"
          ace = acl[perm]

          case member_type
          when "client", "user"
            key = "#{member_type}s"
            key = "actors" unless ace.key? key
            next unless ace[key].include?(member_name)

            ace[key].delete(member_name)
          when "group"
            next unless ace["groups"].include?(member_name)

            ace["groups"].delete(member_name)
          end

          update_ace!(object_type, object_name, perm, ace)
        end
      end

      def update_ace!(object_type, object_name, ace_type, ace)
        rest.put_rest("#{object_type}/#{object_name}/_acl/#{ace_type}", ace_type => ace)
      end

      def add_to_group!(member_type, member_name, group_name)
        validate_member_exists!(member_type, member_name)
        existing_group = rest.get_rest("groups/#{group_name}")
        ui.msg "Adding '#{member_name}' to '#{group_name}' group"
        unless existing_group["#{member_type}s"].include?(member_name)
          existing_group["#{member_type}s"] << member_name
          new_group = {
            "groupname" => existing_group["groupname"],
            "orgname" => existing_group["orgname"],
            "actors" => {
              "users" => existing_group["users"],
              "clients" => existing_group["clients"],
              "groups" => existing_group["groups"],
            },
          }
          rest.put_rest("groups/#{group_name}", new_group)
        end
      end

      def remove_from_group!(member_type, member_name, group_name)
        validate_member_exists!(member_type, member_name)
        existing_group = rest.get_rest("groups/#{group_name}")
        ui.msg "Removing '#{member_name}' from '#{group_name}' group"
        if existing_group["#{member_type}s"].include?(member_name)
          existing_group["#{member_type}s"].delete(member_name)
          new_group = {
            "groupname" => existing_group["groupname"],
            "orgname" => existing_group["orgname"],
            "actors" => {
              "users" => existing_group["users"],
              "clients" => existing_group["clients"],
              "groups" => existing_group["groups"],
            },
          }
          rest.put_rest("groups/#{group_name}", new_group)
        end
      end
    end
  end
end
