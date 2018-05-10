#
# Author:: Stephen Nelson-Smith (<sns@chef.io>)
# Author:: Jon Ramsey (<jonathon.ramsey@gmail.com>)
# Author:: Dave Eddy (<dave@daveeddy.com>)
# Copyright:: Copyright 2012-2018, Chef Software Inc.
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

require "chef/provider/user"

class Chef
  class Provider
    class User
      class Solaris < Chef::Provider::User
        provides :solaris_user
        provides :user, os: %w{omnios solaris2}
        UNIVERSAL_OPTIONS = [[:comment, "-c"], [:gid, "-g"], [:shell, "-s"], [:uid, "-u"]].freeze

        attr_writer :password_file

        def initialize(new_resource, run_context)
          @password_file = "/etc/shadow"
          super
        end

        def create_user
          command = compile_command("useradd") do |useradd|
            useradd.concat(universal_options)
            useradd.concat(useradd_options)
          end
          shell_out_compact!(command)
          manage_password
        end

        def manage_user
          manage_password
          return if universal_options.empty?
          command = compile_command("usermod") do |u|
            u.concat(universal_options)
          end
          shell_out_compact!(command)
        end

        def remove_user
          command = [ "userdel" ]
          command << "-r" if new_resource.manage_home
          command << "-f" if new_resource.force
          command << new_resource.username
          shell_out_compact!(command)
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

        def compile_command(base_command)
          base_command = Array(base_command)
          yield base_command
          base_command << new_resource.username
          base_command
        end

        def universal_options
          @universal_options ||=
            begin
              opts = []
              # magic allows UNIVERSAL_OPTIONS to be overridden in a subclass
              self.class::UNIVERSAL_OPTIONS.each do |field, option|
                update_options(field, option, opts)
              end
              if updating_home?
                opts << "-d" << new_resource.home
                if new_resource.manage_home
                  logger.trace("#{new_resource} managing the users home directory")
                  opts << "-m"
                else
                  logger.trace("#{new_resource} setting home to #{new_resource.home}")
                end
              end
              opts << "-o" if new_resource.non_unique
              opts
            end
        end

        def update_options(field, option, opts)
          return unless current_resource.send(field).to_s != new_resource.send(field).to_s
          return unless new_resource.send(field)
          logger.trace("#{new_resource} setting #{field} to #{new_resource.send(field)}")
          opts << option << new_resource.send(field).to_s
        end

        def updating_home?
          # will return false if paths are equivalent
          # Pathname#cleanpath does a better job than ::File::expand_path (on both unix and windows)
          # ::File.expand_path("///tmp") == ::File.expand_path("/tmp") => false
          # ::File.expand_path("\\tmp") => "C:/tmp"
          return true if current_resource.home.nil? && new_resource.home
          new_resource.home && Pathname.new(current_resource.home).cleanpath != Pathname.new(new_resource.home).cleanpath
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
          logger.trace("#{new_resource} setting password to #{new_resource.password}")
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
