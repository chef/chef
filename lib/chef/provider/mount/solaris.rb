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
        extend Forwardable

        def_delegator :@new_resource, :device, :device
        def_delegator :@new_resource, :dump, :dump
        def_delegator :@new_resource, :fstype, :fstype
        def_delegator :@new_resource, :mount_point, :mount_point
        def_delegator :@new_resource, :options, :options
        def_delegator :@new_resource, :pass, :pass

        def initialize(new_resource, run_context)
          if new_resource.device_type == :device
            Chef::Log.error("Mount resource can only be of of device_type ':device' on Solaris")
          end
          super
        end

        def load_current_resource
          self.current_resource = Chef::Resource::Mount.new(new_resource.name)
          current_resource.mount_point(mount_point)
          current_resource.device(device)
          current_resource.mounted(mounted?)
          current_resource.enabled(enabled?)
        end

        def define_resource_requirements
          requirements.assert(:mount, :remount) do |a|
            a.assertion { !device_should_exist? || ::File.exists?(device) }
            a.failure_message(Chef::Exceptions::Mount, "Device #{device} does not exist")
            a.whyrun("Assuming device #{device} would have been created")
          end

          requirements.assert(:mount, :remount) do |a|
            a.assertion { ::File.exists?(mount_point) }
            a.failure_message(Chef::Exceptions::Mount, "Mount point #{mount_point} does not exist")
            a.whyrun("Assuming mount point #{mount_point} would have been created")
          end
        end

        protected

        def mount_fs
          actual_options = unless options.nil?
                             options(options.delete("noauto"))
                           end
          command = "mount -F #{fstype}"
          command << " -o #{actual_options.join(',')}" unless actual_options.nil?  || actual_options.empty?
          command << " #{device} #{mount_point}"
          shell_out!(command)
        end

        def umount_fs
          shell_out!("umount #{mount_point}")
        end

        def remount_fs
          shell_out!("mount -o remount #{mount_point}")
        end

        def enable_fs
          if !mount_options_unchanged?
            # Options changed: disable first, then re-enable.
            disable_fs if current_resource.enabled
          end

          auto = options.nil? || ! options.include?("noauto")
          actual_options = unless options.nil?
                             options.delete("noauto")
                             options
                           end

          autostr = auto ? 'yes' : 'no'
          passstr = pass == 0 ? "-" : pass
          optstr = (actual_options.nil? || actual_options.empty?) ? "-" : actual_options.join(',')

          Tempfile.open("vfstab", "etc") do |f|
            f.write(IO.read("/etc/vfstab"))
            f.puts("#{device}\t-\t#{mount_point}\t#{fstype}\t#{passstr}\t#{autostr}\t#{optstr}")
            f.close
            FileUtils.mv f.path, "/etc/vfstab"
          end
        end

        def disable_fs
          contents = []

          found = false
          ::File.readlines("/etc/vfstab").reverse_each do |line|
            if !found && line =~ /^#{device_vfstab_regex}\s+[-\/\w]+\s+#{Regexp.escape(mount_point)}/
              found = true
              Chef::Log.debug("#{new_resource} is removed from vfstab")
              next
            end
            contents << line
          end

          Tempfile.open("vfstab", "etc") do |f|
            f.write(contents.reverse)
            f.close
            FileUtils.mv f.path, "/etc/vfstab"
          end
        end

        def mount_options_unchanged?
          current_resource.fstype == fstype and
            current_resource.options == options and
            current_resource.dump == dump and
            current_resource.pass == pass
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
            when /^#{device_vfstab_regex}\s+[-\/\w]+\s+#{Regexp.escape(mount_point)}\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/
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
              Chef::Log.debug("Found mount #{device} to #{mount_point} in /etc/vfstab")
              next
            when /^[-\/\w]+\s+[-\/\w]+\s+#{Regexp.escape(mount_point)}\s+/
              enabled = false
              Chef::Log.debug("Found conflicting mount point #{mount_point} in /etc/vfstab")
            end
          end
          enabled
        end

        def mounted?
          shell_out!("mount").stdout.each_line do |line|
            # on solaris, 'mount' prints "<mount point> on <device> ...'
            case line
            when /^#{Regexp.escape(mount_point)}\s+on\s+#{device_mount_regex}/
              Chef::Log.debug("Special device #{device} is mounted as #{mount_point}")
              return true
            when /^#{Regexp.escape(mount_point)}\son\s([\/\w])+\s+/
              Chef::Log.debug("Special device #{$~[1]} is mounted as #{mount_point}")
            end
          end
          return false
        end

        def device_should_exist?
          device !~ /:/ && device !~ /\/\// && fstype != "tmpfs" && fstype != 'fuse'
        end

        def device_mount_regex
          ::File.symlink?(device) ? "(?:#{Regexp.escape(device)})|(?:#{Regexp.escape(::File.readlink(device))})" : Regexp.escape(device)
        end

        def device_vfstab_regex
          device_mount_regex
        end

      end
    end
  end
end
