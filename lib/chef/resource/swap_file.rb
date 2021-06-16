#
# Copyright:: 2012-2018, Seth Vargo
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../resource"

class Chef
  class Resource
    class SwapFile < Chef::Resource
      unified_mode true

      provides(:swap_file) { true }

      description "Use the **swap_file** resource to create or delete swap files on Linux systems, and optionally to manage the swappiness configuration for a host."
      introduced "14.0"
      examples <<~DOC
      **Create a swap file**

      ```ruby
      swap_file '/dev/sda1' do
        size 1024
      end
      ```

      **Remove a swap file**

      ```ruby
      swap_file '/dev/sda1' do
        action :remove
      end
      ```
      DOC

      property :path, String,
        description: "The path where the swap file will be created on the system if it differs from the resource block's name.",
        name_property: true

      property :size, Integer,
        description: "The size (in MBs) of the swap file."

      property :persist, [TrueClass, FalseClass],
        description: "Persist the swapon.",
        default: false

      property :timeout, Integer,
        description: "Timeout for `dd` / `fallocate` commands.",
        default: 600,
        desired_state: false

      property :swappiness, Integer,
        description: "The swappiness value to set on the system."

      action :create, description: "Create a swapfile." do
        if swap_enabled?
          Chef::Log.debug("#{new_resource} already created - nothing to do")
        else
          begin
            Chef::Log.info "starting first create: #{node["virtualization"]["system"]}"
            do_create(swap_creation_command)
          rescue Mixlib::ShellOut::ShellCommandFailed => e
            Chef::Log.warn("#{new_resource} Rescuing failed swapfile creation for #{new_resource.path}")
            Chef::Log.debug("#{new_resource} Exception when creating swapfile #{new_resource.path}: #{e}")
            do_create(dd_command)
          end
        end
        if new_resource.swappiness
          sysctl "vm.swappiness" do
            value new_resource.swappiness
          end
        end
      end

      action :remove, description: "Remove a swapfile and disable swap." do
        swapoff if swap_enabled?
        remove_swapfile if ::File.exist?(new_resource.path)
      end

      action_class do
        def do_create(command)
          create_swapfile(command)
          set_permissions
          mkswap
          swapon
          persist if persist?
        end

        def create_swapfile(command)
          converge_by "create empty swapfile at #{new_resource.path}" do # ~FC054
            shell_out!(command, timeout: new_resource.timeout)
          end
        end

        def set_permissions
          permissions = "600"
          converge_by "set permissions on #{new_resource.path} to #{permissions}" do
            shell_out!("chmod #{permissions} #{new_resource.path}")
          end
        end

        def mkswap
          converge_by "make #{new_resource.path} swappable" do
            shell_out!("mkswap -f #{new_resource.path}")
          end
        end

        def swapon
          converge_by "enable swap for #{new_resource.path}" do
            shell_out!("swapon #{new_resource.path}")
          end
        end

        def swapoff
          converge_by "turn off swap for #{new_resource.path}" do
            shell_out!("swapoff #{new_resource.path}")
          end
        end

        def remove_swapfile
          converge_by "remove swap file #{new_resource.path}" do
            ::FileUtils.rm(new_resource.path)
          end
        end

        def swap_enabled?
          enabled_swapfiles = shell_out("swapon --summary").stdout
          # Regex for our resource path and only our resource path
          # It will terminate on whitespace after the path it match
          # /testswapfile would match
          # /testswapfiledir/someotherfile will not
          swapfile_regex = Regexp.new("^#{new_resource.path}[\\s\\t\\n\\f]+")
          !swapfile_regex.match(enabled_swapfiles).nil?
        end

        def swap_creation_command
          command = if compatible_filesystem? && compatible_kernel && !docker?
                      fallocate_command
                    else
                      dd_command
                    end
          Chef::Log.debug("#{new_resource} swap creation command is '#{command}'")
          command
        end

        def fallback_swap_creation_command
          command = dd_command
          Chef::Log.debug("#{new_resource} fallback swap creation command is '#{command}'")
          command
        end

        # The block size (1MB)
        def block_size
          1_048_576
        end

        def fallocate_size
          size = block_size * new_resource.size
          Chef::Log.debug("#{new_resource} fallocate size is #{size}")
          size
        end

        def fallocate_command
          size = fallocate_size
          command = "fallocate -l #{size} #{new_resource.path}"
          Chef::Log.debug("#{new_resource} fallocate command is '#{command}'")
          command
        end

        def dd_command
          command = "dd if=/dev/zero of=#{new_resource.path} bs=#{block_size} count=#{new_resource.size}"
          Chef::Log.debug("#{new_resource} dd command is '#{command}'")
          command
        end

        def compatible_kernel
          fallocate_location = shell_out("which fallocate").stdout
          Chef::Log.debug("#{new_resource} fallocate location is '#{fallocate_location}'")
          ::File.exist?(fallocate_location.chomp)
        end

        def compatible_filesystem?
          compatible_filesystems = %w{xfs ext4}
          parent_directory = ::File.dirname(new_resource.path)
          # Get FS info, get second line as first is column headings
          command = "df -PT #{parent_directory} | awk 'NR==2 {print $2}'"
          result = shell_out(command).stdout
          Chef::Log.debug("#{new_resource} filesystem listing is '#{result}'")
          compatible_filesystems.any? { |fs| result.include? fs }
        end

        def persist?
          !!new_resource.persist
        end

        def persist
          fstab = "/etc/fstab"
          contents = ::File.readlines(fstab)
          addition = "#{new_resource.path} swap swap defaults 0 0"

          if contents.any? { |line| line.strip == addition }
            Chef::Log.debug("#{new_resource} already added to /etc/fstab - skipping")
          else
            Chef::Log.info("#{new_resource} adding entry to #{fstab} for #{new_resource.path}")

            contents << "#{addition}\n"
            ::File.open(fstab, "w") { |f| f.write(contents.join("")) }
          end
        end
      end
    end
  end
end
