#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
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

require File.join(File.dirname(__FILE__), "..", "mixin", "command")
require 'etc'

class Chef
  class Provider
    class User < Chef::Provider
      
      include Chef::Mixin::Command
      
      def initialize(node, new_resource)
        super(node, new_resource)
        @user_exists = true
        @locked = nil
      end
  
      def load_current_resource
        @current_resource = Chef::Resource::User.new(@new_resource.name)
        @current_resource.username = @new_resource.username
        
        user_info = nil
        begin
          user_info = Etc.getpwnam(@new_resource.username)
        rescue ArgumentError => e
          @user_exists = false
          Chef::Log.debug("User #{@new_resource.username} does not exist")
        end
        
        if user_info
          @current_resource.uid(user_info.uid)
          @current_resource.gid(user_info.gid)
          @current_resource.comment(user_info.gecos)
          @current_resource.home(user_info.dir)
          @current_resource.shell(user_info.shell)
        
          if @new_resource.password
            begin
              require 'shadow'
            rescue Exception => e
              Chef::Log.error("You must have ruby-shadow installed for password support!")
              raise Chef::Exception::MissingLibrary, "You must have ruby-shadow installed for password support!"
            end
            shadow_info = Shadow::Passwd.getspnam(@new_resource.username)
            @current_resource.password(shadow_info.sp_pwdp)
          end
        end
        
        @current_resource
      end
      
      def compare_user
        change_required = false
        change_required = true if @new_resource.uid != @current_resource.uid
        change_required = true if @new_resource.gid != @current_resource.gid
        change_required = true if @new_resource.comment != @current_resource.comment
        change_required = true if @new_resource.home != @current_resource.home
        change_required = true if @new_resource.shell != @current_resource.shell
        change_required = true if @new_resource.password != @current_resource.password
        change_required
      end
      
      def action_create
        case @user_exists
        when false
          create_user
          Chef::Log.info("Created #{@new_resource}")
          @new_resource.updated(true)
        else 
          if compare_user
            manage_user
            Chef::Log.info("Altered #{@new_resource}")
            @new_resource.updated(true)
          end
        end
      end
      
      def action_remove
        if @user_exists
          remove_user
          @new_resource.updated(true)
          Chef::Log.info("Removed #{@new_resource}")
        end
      end
      
      def action_manage
        if @user_exists && compare_user
          manage_user 
          @new_resource.updated(true)
          Chef::Log.info("Managed #{@new_resource}")
        end
      end
      
      def action_modify
        if @user_exists && compare_user
          manage_user
          @new_resource.updated(true)
          Chef::Log.info("Modified #{@new_resource}")
        else
          raise Chef::Exception::User, "Cannot modify #{@new_resource} - user does not exist!"
        end
      end
      
      def check_lock
        status = popen4("passwd -S #{@new_resource.username}") do |pid, stdin, stdout, stderr|
          stdin.close
          status_line = stdout.gets.split(' ')
          case status_line[1]
          when /^P/
            @locked = false
          when /^N/
            @locked = false
          when /^L/
            @locked = true
          end
        end
        
        unless status.exitstatus == 0
          raise Chef::Exception::User, "Cannot determine if #{@new_resource} is locked!"
        end
        
        @locked
      end
      
      def action_lock
        if @user_exists && check_lock == false
          lock_user
          @new_resource.updated(true)
          Chef::Log.info("Locked #{@new_resource}")
        else
          raise Chef::Exception::User, "Cannot lock #{@new_resource} - user does not exist!"
        end
      end
      
      def action_unlock
        if @user_exists && check_lock = true
          unlock_user
          @new_resource.updated(true)
          Chef::Log.info("Unlocked #{@new_resource}")
        else
          raise Chef::Exception::User, "Cannot unlock #{@new_resource} - user does not exist!"
        end
      end
      
    end
  end
end
