#
# Author:: Hugo Fichter
# Author:: Lamont Granquist (<lamont@getchef.com>)
# Author:: Joshua Timberman (<joshua@getchef.com>)
# Copyright:: Copyright (c) 2009-2014 Chef Software, Inc
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
require 'forwardable'

class Chef
  class Provider
    class Mount
      class Solaris < Chef::Provider::Mount
        include Chef::Mixin::ShellOut
        extend Forwardable

        VFSTAB = "/etc/vfstab".freeze

        def_delegator :@new_resource, :device, :device
        def_delegator :@new_resource, :device_type, :device_type
        def_delegator :@new_resource, :dump, :dump
        def_delegator :@new_resource, :fstype, :fstype
        def_delegator :@new_resource, :mount_point, :mount_point
        def_delegator :@new_resource, :options, :options
        def_delegator :@new_resource, :pass, :pass

        def load_current_resource
          @current_resource = Chef::Resource::Mount.new(new_resource.name)
          current_resource.mount_point(mount_point)
          current_resource.device(device)
          current_resource.device_type(device_type)
          update_current_resource_state
        end

        def define_resource_requirements
          requirements.assert(:mount, :remount) do |a|
            a.assertion { !device_should_exist? || ::File.exist?(device) }
            a.failure_message(Chef::Exceptions::Mount, "Device #{device} does not exist")
            a.whyrun("Assuming device #{device} would have been created")
          end

          requirements.assert(:mount, :remount) do |a|
            a.assertion { ::File.exist?(mount_point) }
            a.failure_message(Chef::Exceptions::Mount, "Mount point #{mount_point} does not exist")
            a.whyrun("Assuming mount point #{mount_point} would have been created")
          end
        end

        def mount_fs
          actual_options = options || []
          actual_options.delete("noauto")
          command = "mount -F #{fstype}"
          command << " -o #{actual_options.join(',')}" unless actual_options.empty?
          command << " #{device} #{mount_point}"
          shell_out!(command)
        end

        def umount_fs
          shell_out!("umount #{mount_point}")
        end

        def remount_fs
          # FIXME: what about options like "-o remount,logging" to enable logging on a UFS device?
          shell_out!("mount -o remount #{mount_point}")
        end

        def enable_fs
          if !mount_options_unchanged?
            # we are enabling because our options have changed, so disable first then re-enable.
            # XXX: this should be refactored to be the responsibility of the caller
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

          etc_tempfile do |f|
            f.write(IO.read(VFSTAB).chomp)
            f.puts("\n#{device}\t-\t#{mount_point}\t#{fstype}\t#{passstr}\t#{autostr}\t#{optstr}")
            f.close
            # move, preserving modes of destination file
            mover = Chef::FileContentManagement::Deploy.strategy(true)
            mover.deploy(f.path, VFSTAB)
          end

        end

        def disable_fs
          contents = []

          found = false
          ::File.readlines(VFSTAB).reverse_each do |line|
            if !found && line =~ /^#{device_regex}\s+\S+\s+#{Regexp.escape(mount_point)}/
              found = true
              Chef::Log.debug("#{new_resource} is removed from vfstab")
              next
            end
            contents << line
          end

          if found
            etc_tempfile do |f|
              f.write(contents.reverse.join(''))
              f.close
              # move, preserving modes of destination file
              mover = Chef::FileContentManagement::Deploy.strategy(true)
              mover.deploy(f.path, VFSTAB)
            end
          else
            # this is likely some kind of internal error, since we should only call disable_fs when there
            # the filesystem we want to disable is enabled.
            Chef::Log.warn("#{new_resource} did not find the mountpoint to disable in the vfstab")
          end
        end

        def etc_tempfile
          yield Tempfile.open("vfstab", "/etc")
        end

        def mount_options_unchanged?
          current_resource.fstype == fstype and
            current_resource.options == options and
            current_resource.dump == dump and
            current_resource.pass == pass
        end

        def update_current_resource_state
          current_resource.mounted(mounted?)
          ( enabled, fstype, options, pass ) = read_vfstab_status
          current_resource.enabled(enabled)
          current_resource.fstype(fstype)
          current_resource.options(options)
          current_resource.pass(pass)
        end

        def enabled?
          read_vfstab_status[0]
        end

        def mounted?
          mounted = false
          shell_out!("mount -v").stdout.each_line do |line|
            # <device> on <mountpoint> type <fstype> <options> on <date>
            # /dev/dsk/c1t0d0s0 on / type ufs read/write/setuid/devices/intr/largefiles/logging/xattr/onerror=panic/dev=700040 on Tue May  1 11:33:55 2012
            case line
            when /^#{device_regex}\s+on\s+#{Regexp.escape(mount_point)}\s+/
              Chef::Log.debug("Special device #{device} is mounted as #{mount_point}")
              mounted = true
            when /^([\/\w]+)\son\s#{Regexp.escape(mount_point)}\s+/
              Chef::Log.debug("Special device #{$1} is mounted as #{mount_point}")
              mounted = false
            end
          end
          mounted
        end

        private

        def read_vfstab_status
          # Check to see if there is a entry in /etc/vfstab. Last entry for a volume wins.
          enabled = false
          fstype = options = pass = nil
          ::File.foreach(VFSTAB) do |line|
            case line
            when /^[#\s]/
              next
              # solaris /etc/vfstab format:
              # device         device          mount           FS      fsck    mount   mount
              # to mount       to fsck         point           type    pass    at boot options
            when /^#{device_regex}\s+[-\/\w]+\s+#{Regexp.escape(mount_point)}\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/
              enabled = true
              fstype = $1
              options = $4
              # Store the 'mount at boot' column from vfstab as the 'noauto' option
              # in current_resource.options (linux style)
              if $3 == "yes"
                if options.nil? || options.empty?
                  options = "noauto"
                else
                  options += ",noauto"
                end
              end
              pass = ( $2 == "-" ) ? 0 : $2.to_i
              Chef::Log.debug("Found mount #{device} to #{mount_point} in #{VFSTAB}")
              next
            when /^[-\/\w]+\s+[-\/\w]+\s+#{Regexp.escape(mount_point)}\s+/
              # if we find a mountpoint on top of our mountpoint, then we are not enabled
              enabled = false
              Chef::Log.debug("Found conflicting mount point #{mount_point} in #{VFSTAB}")
            end
          end
          [ enabled, fstype, options, pass ]
        end

        def device_should_exist?
          !%w{tmpfs nfs ctfs proc mntfs objfs sharefs fd smbfs}.include?(fstype)
        end

        def device_regex
          if ::File.symlink?(device)
            "(?:#{Regexp.escape(device)}|#{Regexp.escape(::File.expand_path(::File.readlink(device),::File.dirname(device)))})"
          else
            Regexp.escape(device)
          end
        end

      end
    end
  end
end
