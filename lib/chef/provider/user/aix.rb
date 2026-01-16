#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "../user"

class Chef
  class Provider
    class User
      class Aix < Chef::Provider::User
        provides :user, os: "aix", target_mode: true
        provides :aix_user, target_mode: true

        # The ruby-shadow gem is not supported on aix.
        def supports_ruby_shadow?
          false
        end

        def create_user
          shell_out!("useradd", universal_options, useradd_options, new_resource.username)
          add_password
        end

        def manage_user
          add_password
          manage_home
          return if universal_options.empty? && usermod_options.empty?

          shell_out!("usermod", universal_options, usermod_options, new_resource.username)
        end

        def remove_user
          shell_out!("userdel", userdel_options, new_resource.username)
        end

        # Aix does not support -r like other unix, system account is created by adding to 'system' group
        def useradd_options
          opts = []
          opts << "-g" << "system" if new_resource.system
          if updating_home?
            if new_resource.manage_home
              logger.trace("#{new_resource} managing the users home directory")
              opts << "-m"
            else
              logger.trace("#{new_resource} setting home to #{new_resource.home}")
            end
          end
          opts
        end

        def userdel_options
          opts = []
          opts << "-r" if new_resource.manage_home
          opts << "-f" if new_resource.force
          opts
        end

        def usermod_options
          []
        end

        def check_lock
          lock_info = shell_out!("lsuser", "-a", "account_locked", new_resource.username)
          if whyrun_mode? && passwd_s.stdout.empty? && lock_info.stderr.include?("does not exist")
            # if we're in whyrun mode and the user is not yet created we assume it would be
            return false
          end
          raise Chef::Exceptions::User, "Cannot determine if #{new_resource} is locked!" if lock_info.stdout.empty?

          status = /\S+\s+account_locked=(\S+)/.match(lock_info.stdout)
          @locked =
            if status && status[1] == "true"
              true
            else
              false
            end

          @locked
        end

        def lock_user
          shell_out!("chuser", "account_locked=true", new_resource.username)
        end

        def unlock_user
          shell_out!("chuser", "account_locked=false", new_resource.username)
        end

        def universal_options
          opts = []
          opts << "-c" << new_resource.comment if should_set?(:comment)
          opts << "-g" << new_resource.gid if should_set?(:gid)
          opts << "-s" << new_resource.shell if should_set?(:shell)
          opts << "-u" << new_resource.uid if should_set?(:uid)
          opts << "-d" << new_resource.home if updating_home?
          opts << "-o" if new_resource.non_unique
          opts
        end

        private

        def add_password
          return unless current_resource.password != new_resource.password && new_resource.password

          logger.trace("#{new_resource.username} setting password to #{new_resource.password}")
          command = "echo '#{new_resource.username}:#{new_resource.password}' | chpasswd -c -e"
          shell_out!(command)
        end

        # Aix specific handling to update users home directory.
        def manage_home
          return unless updating_home? && new_resource.manage_home

          # -m option does not work on aix, so move dir.
          if ::TargetIO::File.directory?(current_resource.home)
            logger.trace("Changing users home directory from #{current_resource.home} to #{new_resource.home}")
            FileUtils.mv current_resource.home, new_resource.home
          else
            logger.trace("Creating users home directory #{new_resource.home}")
            FileUtils.mkdir_p new_resource.home
          end
        end

      end
    end
  end
end
