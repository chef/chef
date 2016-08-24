#
# Copyright:: Copyright 2016, Chef Software Inc.
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

require "chef/provider/user"

class Chef
  class Provider
    class User
      class Linux < Chef::Provider::User
        provides :linux_user
        provides :user, os: "linux"

        def create_user
          shell_out!(*clean_array("useradd", universal_options, useradd_options, new_resource.username))
        end

        def manage_user
          shell_out!(*clean_array("usermod", universal_options, usermod_options, new_resource.username))
        end

        def remove_user
          shell_out!(*clean_array("userdel", userdel_options, new_resource.username))
        end

        def lock_user
          shell_out!(*clean_array("usermod", "-L", new_resource.username))
        end

        def unlock_user
          shell_out!(*clean_array("usermod", "-U", new_resource.username))
        end

        # common to usermod and useradd
        def universal_options
          opts = []
          opts << "-c" << new_resource.comment if should_set?(:comment)
          opts << "-g" << new_resource.gid if should_set?(:gid)
          opts << "-p" << new_resource.password if should_set?(:password)
          opts << "-s" << new_resource.shell if should_set?(:shell)
          opts << "-u" << new_resource.uid if should_set?(:uid)
          opts << "-d" << new_resource.home if updating_home?
          opts << "-o" if new_resource.non_unique
          opts
        end

        def usermod_options
          opts = []
          if updating_home?
            if new_resource.manage_home
              opts << "-m"
            end
          end
          opts
        end

        def useradd_options
          opts = []
          opts << "-r" if new_resource.system
          if new_resource.manage_home
            opts << "-m"
          else
            opts << "-M"
          end
          opts
        end

        def userdel_options
          opts = []
          opts << "-r" if new_resource.manage_home
          opts << "-f" if new_resource.force
          opts
        end

        def should_set?(sym)
          current_resource.send(sym).to_s != new_resource.send(sym).to_s && new_resource.send(sym)
        end

        def updating_home?
          return false unless new_resource.home
          return true unless current_resource.home
          new_resource.home && Pathname.new(current_resource.home).cleanpath != Pathname.new(new_resource.home).cleanpath
        end

        # FIXME: see if we can clean this up
        def check_lock
          # we can get an exit code of 1 even when it's successful on
          # rhel/centos (redhat bug 578534). See additional error checks below.
          passwd_s = shell_out!("passwd", "-S", new_resource.username, :returns => [0, 1])
          if whyrun_mode? && passwd_s.stdout.empty? && passwd_s.stderr.match(/does not exist/)
            # if we're in whyrun mode and the user is not yet created we assume it would be
            return false
          end

          raise Chef::Exceptions::User, "Cannot determine if #{@new_resource} is locked!" if passwd_s.stdout.empty?

          status_line = passwd_s.stdout.split(" ")
          case status_line[1]
          when /^P/
            @locked = false
          when /^N/
            @locked = false
          when /^L/
            @locked = true
          end

          unless passwd_s.exitstatus == 0
            raise_lock_error = false
            if %w{redhat centos}.include?(node[:platform])
              passwd_version_check = shell_out!("rpm -q passwd")
              passwd_version = passwd_version_check.stdout.chomp

              unless passwd_version == "passwd-0.73-1"
                raise_lock_error = true
              end
            else
              raise_lock_error = true
            end

            raise Chef::Exceptions::User, "Cannot determine if #{new_resource} is locked!" if raise_lock_error
          end

          @locked
        end
      end
    end
  end
end
