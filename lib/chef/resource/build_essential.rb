#
# Copyright:: 2008-2018, Chef Software, Inc.
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

require "chef/resource"

class Chef
  class Resource
    class BuildEssential < Chef::Resource
      resource_name :build_essential
      provides :build_essential

      property :compile_time, [true, false], default: false

      action :install do
        case node["platform_family"]
        when "debian"
          declare_resource(:package,  %w{ autoconf binutils-doc bison build-essential flex gettext ncurses-dev })
        when "amazon", "fedora", "rhel"
          declare_resource(:package,  %w{ autoconf bison flex gcc gcc-c++ gettext kernel-devel make m4 ncurses-devel patch })

          # Ensure GCC 4 is available on older pre-6 EL
          declare_resource(:package,  %w{ gcc44 gcc44-c++ }) if node["platform_version"].to_i < 6
        when "freebsd"
          declare_resource(:package,  "devel/gmake")
          declare_resource(:package,  "devel/autoconf")
          declare_resource(:package,  "devel/m4")
          declare_resource(:package,  "devel/gettext")
        when "mac_os_x"
          # This script was graciously borrowed and modified from Tim Sutton's
          # osx-vm-templates at https://github.com/timsutton/osx-vm-templates/blob/b001475df54a9808d3d56d06e71b8fa3001fff42/scripts/xcode-cli-tools.sh
          declare_resource(:execute, "install XCode Command Line tools") do
            command <<-EOH.gsub(/^ {14}/, "")
              # create the placeholder file that's checked by CLI updates' .dist code
              # in Apple's SUS catalog
              touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
              # find the CLI Tools update
              PROD=$(softwareupdate -l | grep "\*.*Command Line" | head -n 1 | awk -F"*" '{print $2}' | sed -e 's/^ *//' | tr -d '\n')
              # install it
              softwareupdate -i "$PROD" --verbose
              # Remove the placeholder to prevent perpetual appearance in the update utility
              rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
            EOH
            # rubocop:enable Metrics/LineLength
          end
        when "omnios"
          declare_resource(:package,  "developer/gcc48")
          declare_resource(:package,  "developer/object-file")
          declare_resource(:package,  "developer/linker")
          declare_resource(:package,  "developer/library/lint")
          declare_resource(:package,  "developer/build/gnu-make")
          declare_resource(:package,  "system/header")
          declare_resource(:package,  "system/library/math/header-math")

          # Per OmniOS documentation, the gcc bin dir isn't in the default
          # $PATH, so add it to the running process environment
          # http://omnios.omniti.com/wiki.php/DevEnv
          ENV["PATH"] = "#{ENV['PATH']}:/opt/gcc-4.7.2/bin"
        when "solaris2"
          declare_resource(:package,  "autoconf")
          declare_resource(:package,  "automake")
          declare_resource(:package,  "bison")
          declare_resource(:package,  "gnu-coreutils")
          declare_resource(:package,  "flex")
          declare_resource(:package,  "gcc") do
            # lock because we don't use 5 yet
            version "4.8.2"
          end
          declare_resource(:package,  "gcc-3")
          declare_resource(:package,  "gnu-grep")
          declare_resource(:package,  "gnu-make")
          declare_resource(:package,  "gnu-patch")
          declare_resource(:package,  "gnu-tar")
          declare_resource(:package,  "make")
          declare_resource(:package,  "pkg-config")
          declare_resource(:package,  "ucb")
        when "smartos"
          declare_resource(:package,  "autoconf")
          declare_resource(:package,  "binutils")
          declare_resource(:package,  "build-essential")
          declare_resource(:package,  "gcc47")
          declare_resource(:package,  "gmake")
          declare_resource(:package,  "pkg-config")
        when "suse"
          declare_resource(:package,  %w{ autoconf bison flex gcc gcc-c++ kernel-default-devel make m4 })
          declare_resource(:package,  %w{ gcc48 gcc48-c++ }) if node["platform_version"].to_i < 12
        else
          Chef::Log.warn <<-EOH
        The build_essential resource does not currently support the '#{node['platform_family']}'
        platform family. Skipping...
        EOH
        end
      end

      # this resource forces itself to run at compile_time
      def after_created
        return unless compile_time
        Array(action).each do |action|
          run_action(action)
        end
      end
    end
  end
end
