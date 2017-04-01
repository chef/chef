#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

require "chef/provider"
require "etc"

class Chef
  class Provider
    class User < Chef::Provider

      attr_accessor :user_exists, :locked

      def initialize(new_resource, run_context)
        super
        @user_exists = true
        @locked = nil
        @shadow_lib_ok = true
        @group_name_resolved = true
      end

      def convert_group_name
        if new_resource.gid.is_a? String
          new_resource.gid(Etc.getgrnam(new_resource.gid).gid)
        end
      rescue ArgumentError
        @group_name_resolved = false
      end

      def load_current_resource
        @current_resource = Chef::Resource::User.new(new_resource.name)
        current_resource.username(new_resource.username)

        begin
          user_info = Etc.getpwnam(new_resource.username)
        rescue ArgumentError
          @user_exists = false
          Chef::Log.debug("#{new_resource} user does not exist")
          user_info = nil
        end

        if user_info
          current_resource.uid(user_info.uid)
          current_resource.gid(user_info.gid)
          current_resource.home(user_info.dir)
          current_resource.shell(user_info.shell)
          current_resource.password(user_info.passwd)

          if new_resource.comment
            user_info.gecos.force_encoding(new_resource.comment.encoding)
          end
          current_resource.comment(user_info.gecos)

          if new_resource.password && current_resource.password == "x"
            begin
              require "shadow"
            rescue LoadError
              @shadow_lib_ok = false
            else
              shadow_info = Shadow::Passwd.getspnam(new_resource.username)
              current_resource.password(shadow_info.sp_pwdp)
            end
          end

          convert_group_name if new_resource.gid
        end

        current_resource
      end

      def define_resource_requirements
        requirements.assert(:create, :modify, :manage, :lock, :unlock) do |a|
          a.assertion { @group_name_resolved }
          a.failure_message Chef::Exceptions::User, "Couldn't lookup integer GID for group name #{new_resource.gid}"
          a.whyrun "group name #{new_resource.gid} does not exist.  This will cause group assignment to fail.  Assuming this group will have been created previously."
        end
        requirements.assert(:all_actions) do |a|
          a.assertion { @shadow_lib_ok }
          a.failure_message Chef::Exceptions::MissingLibrary, "You must have ruby-shadow installed for password support!"
          a.whyrun "ruby-shadow is not installed. Attempts to set user password will cause failure.  Assuming that this gem will have been previously installed." \
            "Note that user update converge may report false-positive on the basis of mismatched password. "
        end
        requirements.assert(:modify, :lock, :unlock) do |a|
          a.assertion { @user_exists }
          a.failure_message(Chef::Exceptions::User, "Cannot modify user #{new_resource.username} - does not exist!")
          a.whyrun("Assuming user #{new_resource.username} would have been created")
        end
      end

      # Check to see if the user needs any changes
      #
      # === Returns
      # <true>:: If a change is required
      # <false>:: If the users are identical
      def compare_user
        return true if !new_resource.home.nil? && Pathname.new(new_resource.home).cleanpath != Pathname.new(current_resource.home).cleanpath

        [ :comment, :shell, :password, :uid, :gid ].each do |user_attrib|
          return true if !new_resource.send(user_attrib).nil? && new_resource.send(user_attrib).to_s != current_resource.send(user_attrib).to_s
        end

        false
      end

      def action_create
        if !@user_exists
          converge_by("create user #{new_resource.username}") do
            create_user
            Chef::Log.info("#{new_resource} created")
          end
        elsif compare_user
          converge_by("alter user #{new_resource.username}") do
            manage_user
            Chef::Log.info("#{new_resource} altered")
          end
        end
      end

      def action_remove
        return unless @user_exists
        converge_by("remove user #{new_resource.username}") do
          remove_user
          Chef::Log.info("#{new_resource} removed")
        end
      end

      def action_manage
        return unless @user_exists && compare_user
        converge_by("manage user #{new_resource.username}") do
          manage_user
          Chef::Log.info("#{new_resource} managed")
        end
      end

      def action_modify
        return unless compare_user
        converge_by("modify user #{new_resource.username}") do
          manage_user
          Chef::Log.info("#{new_resource} modified")
        end
      end

      def action_lock
        if check_lock == false
          converge_by("lock the user #{new_resource.username}") do
            lock_user
            Chef::Log.info("#{new_resource} locked")
          end
        else
          Chef::Log.debug("#{new_resource} already locked - nothing to do")
        end
      end

      def action_unlock
        if check_lock == true
          converge_by("unlock user #{new_resource.username}") do
            unlock_user
            Chef::Log.info("#{new_resource} unlocked")
          end
        else
          Chef::Log.debug("#{new_resource} already unlocked - nothing to do")
        end
      end

      def create_user
        raise NotImplementedError
      end

      def remove_user
        raise NotImplementedError
      end

      def manage_user
        raise NotImplementedError
      end

      def lock_user
        raise NotImplementedError
      end

      def unlock_user
        raise NotImplementedError
      end

      def check_lock
        raise NotImplementedError
      end
    end
  end
end
