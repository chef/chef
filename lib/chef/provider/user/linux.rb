#
# Copyright:: Copyright 2016-2017, Chef Software Inc.
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
          shell_out_compact!("useradd", universal_options, useradd_options, new_resource.username)
        end

        def manage_user
          shell_out_compact!("usermod", universal_options, usermod_options, new_resource.username)
        end

        def remove_user
          shell_out_compact!("userdel", userdel_options, new_resource.username)
        end

        def lock_user
          shell_out_compact!("usermod", "-L", new_resource.username)
        end

        def unlock_user
          shell_out_compact!("usermod", "-U", new_resource.username)
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
          opts += [ "-u", new_resource.uid ] if new_resource.non_unique
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
          opts << if new_resource.manage_home
                    "-m"
                  else
                    "-M"
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

        def check_lock
          # there's an old bug in rhel (https://bugzilla.redhat.com/show_bug.cgi?id=578534)
          # which means that both 0 and 1 can be success.
          passwd_s = shell_out_compact("passwd", "-S", new_resource.username, returns: [ 0, 1 ])

          # checking "does not exist" has to come before exit code handling since centos and ubuntu differ in exit codes
          if passwd_s.stderr =~ /does not exist/
            return false if whyrun_mode?
            raise Chef::Exceptions::User, "User #{new_resource.username} does not exist when checking lock status for #{new_resource}"
          end

          # now raise if we didn't get a 0 or 1 (see above)
          passwd_s.error!

          # now the actual output parsing
          @locked = nil
          status_line = passwd_s.stdout.split(" ")
          @locked = false if status_line[1] =~ /^[PN]/
          @locked = true if status_line[1] =~ /^L/

          raise Chef::Exceptions::User, "Cannot determine if user #{new_resource.username} is locked for #{new_resource}" if @locked.nil?

          # FIXME: should probably go on the current_resource
          @locked
        end
      end
    end
  end
end
