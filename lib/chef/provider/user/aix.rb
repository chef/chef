#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

class Chef
  class Provider
    class User
      class Aix < Chef::Provider::User::Useradd
        provides :user, platform: %w(aix)

        UNIVERSAL_OPTIONS = [[:comment, "-c"], [:gid, "-g"], [:shell, "-s"], [:uid, "-u"]]

        def create_user
          super
          add_password
        end

        def manage_user
          add_password
          manage_home
          super
        end

        # Aix does not support -r like other unix, sytem account is created by adding to 'system' group
        def useradd_options
          opts = []
          opts << "-g" << "system" if new_resource.system
          opts
        end

        def check_lock
          lock_info = shell_out!("lsuser -a account_locked #{new_resource.username}")
          if whyrun_mode? && passwd_s.stdout.empty? && lock_info.stderr.match(/does not exist/)
            # if we're in whyrun mode and the user is not yet created we assume it would be
            return false
          end
          raise Chef::Exceptions::User, "Cannot determine if #{@new_resource} is locked!" if lock_info.stdout.empty?

          status  = /\S+\s+account_locked=(\S+)/.match(lock_info.stdout)
          if status && status[1] == "true"
            @locked = true
          else
            @locked = false
          end

          @locked
        end

        def lock_user
          shell_out!("chuser account_locked=true #{new_resource.username}")
        end

        def unlock_user
          shell_out!("chuser account_locked=false #{new_resource.username}")
        end

      private
        def add_password
          if @current_resource.password != @new_resource.password && @new_resource.password
            Chef::Log.debug("#{@new_resource.username} setting password to #{@new_resource.password}")
            command = "echo '#{@new_resource.username}:#{@new_resource.password}' | chpasswd -e"
            shell_out!(command)
          end
        end

        # Aix specific handling to update users home directory.
        def manage_home
          # -m option does not work on aix, so move dir.
          if updating_home? and managing_home_dir?
            universal_options.delete("-m")
            if ::File.directory?(@current_resource.home)
              Chef::Log.debug("Changing users home directory from #{@current_resource.home} to #{new_resource.home}")
              shell_out!("mv #{@current_resource.home} #{new_resource.home}")
            else
              Chef::Log.debug("Creating users home directory #{new_resource.home}")
              shell_out!("mkdir -p #{new_resource.home}")
            end
          end
        end

      end
    end
  end
end
