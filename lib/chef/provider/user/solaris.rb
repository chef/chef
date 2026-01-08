#
# Author:: Stephen Nelson-Smith (<sns@chef.io>)
# Author:: Jon Ramsey (<jonathon.ramsey@gmail.com>)
# Author:: Dave Eddy (<dave@daveeddy.com>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# Copyright:: Copyright 2015-2016, Dave Eddy
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
      class Solaris < Chef::Provider::User
        provides :solaris_user, target_mode: true
        provides :user, os: %w{openindiana illumos omnios solaris2 smartos}, target_mode: true

        PASSWORD_FILE = "/etc/shadow".freeze

        def create_user
          shell_out!("useradd", universal_options, useradd_options, new_resource.username)
          manage_password
        end

        def manage_user
          manage_password
          return if universal_options.empty? && usermod_options.empty?

          shell_out!("usermod", universal_options, usermod_options, new_resource.username)
        end

        def remove_user
          shell_out!("userdel", userdel_options, new_resource.username)
        end

        def check_lock
          user = TargetIO::IO.read(PASSWORD_FILE).match(/^#{Regexp.escape(new_resource.username)}:([^:]*):/)

          # If we're in whyrun mode, and the user is not created, we assume it will be
          return false if whyrun_mode? && user.nil?

          raise Chef::Exceptions::User, "Cannot determine if #{new_resource} is locked!" if user.nil?

          @locked = user[1].start_with?("*LK*")
        end

        def lock_user
          shell_out!("passwd", "-l", new_resource.username)
        end

        def unlock_user
          shell_out!("passwd", "-u", new_resource.username)
        end

        private

        def universal_options
          opts = []
          opts << "-c" << new_resource.comment if should_set?(:comment)
          opts << "-g" << new_resource.gid if should_set?(:gid)
          opts << "-s" << new_resource.shell if should_set?(:shell)
          opts << "-u" << new_resource.uid if should_set?(:uid)
          opts << "-d" << new_resource.home if updating_home?
          opts << "-o" if new_resource.non_unique
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

        def userdel_options
          opts = []
          opts << "-r" if new_resource.manage_home
          opts << "-f" if new_resource.force
          opts
        end

        # Solaris does not support system users and has no '-r' option, solaris also
        # lacks '-M' and defaults to no-manage-home.
        def useradd_options
          opts = []
          opts << "-m" if new_resource.manage_home
          opts
        end

        def manage_password
          return unless current_resource.password != new_resource.password && new_resource.password

          logger.trace("#{new_resource} setting password to #{new_resource.password}")
          write_shadow_file
        end

        # XXX: this was straight copypasta'd back in 2013 and I don't think we've ever evaluated using
        # a pipe to passwd(1) or evaluating modern ruby-shadow.  See https://github.com/chef/chef/pull/721
        def write_shadow_file
          buffer = Tempfile.new("shadow", "/etc")
          ::TargetIO::File.open(PASSWORD_FILE) do |shadow_file|
            shadow_file.each do |entry|
              user = entry.split(":").first
              if user == new_resource.username
                buffer.write(updated_password(entry))
              else
                buffer.write(entry)
              end
            end
          end
          buffer.close

          # FIXME: mostly duplicates code with file provider deploying a file
          s = ::File.stat(PASSWORD_FILE)
          mode = s.mode & 0o7777
          uid  = s.uid
          gid  = s.gid

          TargetIO::FileUtils.chown uid, gid, buffer.path
          TargetIO::FileUtils.chmod mode, buffer.path

          TargetIO::FileUtils.mv buffer.path, PASSWORD_FILE
        end

        def updated_password(entry)
          fields = entry.split(":")
          fields[1] = new_resource.password
          fields[2] = days_since_epoch
          fields.join(":")
        end

        def days_since_epoch
          (Time.now.to_i / 86400).floor
        end
      end
    end
  end
end
