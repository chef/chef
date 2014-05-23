#
# Author:: Hugo Fichter
# Author:: Lamont Granquist (<lamont@getchef.com>)
# Author:: Joshua Timberman (<joshua@getchef.com>)
# Copyright:: Copyright (c) 2009-2014 Opscode, Inc
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

require 'chef/provider/mount'
require 'chef/log'
require 'chef/mixin/shell_out'

class Chef
  class Provider
    class Mount
      class Solaris < Chef::Provider::Mount
        include Chef::Mixin::ShellOut

        def initialize(new_resource, run_context)
          if new_resource.device_type == :device
            Chef::Log.error("Mount resource can only be of of device_type ':device' on Solaris")
          end
          super
        end

        def load_current_resource
          self.current_resource = Chef::Resource::Mount.new(new_resource.name)
          current_resource.mount_point(new_resource.mount_point)
          current_resource.device(new_resource.device)
          current_resource.mounted(mounted?)
          current_resource.enabled(enabled?)
        end

        def define_resource_requirements do
          requirements.assert(:mount, :remount) do |a|
            a.assertion { !device_should_exist? || ::File.exists?(new_resource.device) }
            a.failure_message(Chef::Exceptions::Mount, "Device #{new_resource.device} does not exist")
            a.whyrun("Assuming device #{new_resource.device} would have been created")
          end

          requirements.assert(:mount, :remount) do |a|
            a.assertion { ::File.exists?(new_resource.mount_point) }
            a.failure_message(Chef::Exceptions::Mount, "Mount point #{new_resource.mount_point} does not exist")
            a.whyrun("Assuming mount point #{new_resource.mount_point} would have been created")
          end
        end

        protected

        def mount_fs
          actual_options = unless new_resource.options.nil?
                             new_resource.options(new_resource.options.delete("noauto"))
                           end
          command = "mount -F #{new_resource.fstype}"
          command << " -o #{actual_options.join(',')}" unless actual_options.nil?  || actual_options.empty?
          command << " #{new_resource.device}"
          command << " #{new_resource.mount_point}"
          shell_out!(command)
        end

        def umount_fs
          shell_out!("umount #{new_resource.mount_point}")
        end

        def remount_fs
          shell_out!("mount -o remount #{new_resource.mount_point}")
        end

        def enable_fs
          if !mount_options_unchanged?
            # Options changed: disable first, then re-enable.
            disable_fs if current_resource.enabled
          end

          # FIXME: open a tempfile, write to it, close it, then rename it.
          ::File.open("/etc/vfstab", "a") do |fstab|
            auto = new_resource.options.nil? || ! new_resource.options.include?("noauto")
            actual_options = unless new_resource.options.nil?
                               new_resource.options.delete("noauto")
                               new_resource.options
                             end
            fstab.puts("#{new_resource.device}\t-\t#{new_resource.mount_point}\t#{new_resource.fstype}\t#{new_resource.pass == 0 ? "-" : new_resource.pass}\t#{ auto ? :yes : :no }\t #{(actual_options.nil? || actual_options.empty?) ? "-" : actual_options.join(',')}")
          end
        end

        def disable_fs
          contents = []

          # FIXME: open a tempfile, write to it, close it, then rename it.
          found = false
          ::File.readlines("/etc/vfstab").reverse_each do |line|
            if !found && line =~ /^#{device_vfstab_regex}\s+[-\/\w]+\s+#{Regexp.escape(new_resource.mount_point)}/
              found = true
              Chef::Log.debug("#{new_resource} is removed from vfstab")
              next
            else
              contents << line
            end
          end

          ::File.open("/etc/vfstab", "w") do |fstab|
            contents.reverse_each { |line| fstab.puts line}
          end
        end

        def mount_options_unchanged?
          current_resource.fstype == new_resource.fstype and
            current_resource.options == new_resource.options and
            current_resource.dump == new_resource.dump and
            current_resource.pass == new_resource.pass
        end

        private

        def enabled?
          # Check to see if there is a entry in /etc/vfstab. Last entry for a volume wins.
          enabled = false
          ::File.foreach("/etc/vfstab") do |line|
            case line
            when /^[#\s]/
              next
              # solaris /etc/vfstab format:
              # device         device          mount           FS      fsck    mount   mount
              # to mount       to fsck         point           type    pass    at boot options
            when /^#{device_vfstab_regex}\s+[-\/\w]+\s+#{Regexp.escape(new_resource.mount_point)}\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/
              enabled = true
              current_resource.fstype($1)
              # Store the 'mount at boot' column from vfstab as the 'noauto' option
              # in current_resource.options (linux style)
              no_auto_option = ($3 == "yes")
              options = $4
              if no_auto_option
                if options.nil? || options.empty?
                  options = "noauto"
                else
                  options += ",noauto"
                end
              end
              current_resource.options(options)
              if $2 == "-"
                pass = 0
              else
                pass = $2.to_i
              end
              current_resource.pass(pass)
              Chef::Log.debug("Found mount #{new_resource.device} to #{new_resource.mount_point} in /etc/vfstab")
              next
            when /^[-\/\w]+\s+[-\/\w]+\s+#{Regexp.escape(new_resource.mount_point)}\s+/
              enabled = false
              Chef::Log.debug("Found conflicting mount point #{new_resource.mount_point} in /etc/vfstab")
            end
          end
          enabled
        end

        def mounted?
          shell_out!("mount").stdout.each_line do |line|
            # on solaris, 'mount' prints "<mount point> on <device> ...'
            case line
            when /^#{Regexp.escape(new_resource.mount_point)}\s+on\s+#{device_mount_regex}/
              Chef::Log.debug("Special device #{new_resource.device} is mounted as #{new_resource.mount_point}")
              return true
            when /^#{Regexp.escape(new_resource.mount_point)}\son\s([\/\w])+\s+/
              Chef::Log.debug("Special device #{$~[1]} is mounted as #{new_resource.mount_point}")
            end
          end
          return false
        end

        def device_should_exist?
          new_resource.device !~ /:/ && new_resource.device !~ /\/\// && new_resource.fstype != "tmpfs" && new_resource.fstype != 'fuse'
        end

        def device_mount_regex
          ::File.symlink?(new_resource.device) ? "(?:#{Regexp.escape(new_resource.device)})|(?:#{Regexp.escape(::File.readlink(new_resource.device))})" : Regexp.escape(new_resource.device)
        end

        def device_vfstab_regex
          device_mount_regex
        end

      end
    end
  end
end
