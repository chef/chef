#
# Author:: Stephen Nelson-Smith (<sns@chef.io>)
# Author:: Jon Ramsey (<jonathon.ramsey@gmail.com>)
# Author:: Dave Eddy (<dave@daveeddy.com>)
# Copyright:: Copyright 2012-2017, Chef Software Inc.
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

require "chef/provider/user/useradd"

class Chef
  class Provider
    class User
      class Solaris < Chef::Provider::User::Useradd
        provides :solaris_user
        provides :user, os: %w{omnios solaris2}
        UNIVERSAL_OPTIONS = [[:comment, "-c"], [:gid, "-g"], [:shell, "-s"], [:uid, "-u"]].freeze

        attr_writer :password_file

        def initialize(new_resource, run_context)
          @password_file = "/etc/shadow"
          super
        end

        def create_user
          super
          manage_password
        end

        def manage_user
          manage_password
          super
        end

        def check_lock
          user = IO.read(@password_file).match(/^#{Regexp.escape(new_resource.username)}:([^:]*):/)

          # If we're in whyrun mode, and the user is not created, we assume it will be
          return false if whyrun_mode? && user.nil?

          raise Chef::Exceptions::User, "Cannot determine if #{new_resource} is locked!" if user.nil?

          @locked = user[1].start_with?("*LK*")
        end

        def lock_user
          shell_out_compact!("passwd", "-l", new_resource.username)
        end

        def unlock_user
          shell_out_compact!("passwd", "-u", new_resource.username)
        end

        private

        # Override the version from {#Useradd} because Solaris doesn't support
        # system users and therefore has no `-r` option. This also inverts the
        # logic for manage_home as Solaris defaults to no-manage-home and only
        # offers `-m`.
        #
        # @since 12.15
        # @api private
        # @see Useradd#useradd_options
        # @return [Array<String>]
        def useradd_options
          opts = []
          opts << "-m" if new_resource.manage_home
          opts
        end

        def manage_password
          return unless current_resource.password != new_resource.password && new_resource.password
          Chef::Log.debug("#{new_resource} setting password to #{new_resource.password}")
          write_shadow_file
        end

        def write_shadow_file
          buffer = Tempfile.new("shadow", "/etc")
          ::File.open(@password_file) do |shadow_file|
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
          s = ::File.stat(@password_file)
          mode = s.mode & 0o7777
          uid  = s.uid
          gid  = s.gid

          FileUtils.chown uid, gid, buffer.path
          FileUtils.chmod mode, buffer.path

          FileUtils.mv buffer.path, @password_file
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
