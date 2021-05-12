#
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
    class BuildEssential < Chef::Resource
      unified_mode true

      provides(:build_essential) { true }

      description "Use the **build_essential** resource to install the packages required for compiling C software from source."
      introduced "14.0"
      examples <<~DOC
        **Install compilation packages**:

        ```ruby
        build_essential
        ```

        **Install compilation packages during the compilation phase**:

        ```ruby
        build_essential 'Install compilation tools' do
          compile_time true
        end
        ```

        **Upgrade compilation packages on macOS systems**:

        ```ruby
        build_essential 'Install compilation tools' do
          action :upgrade
        end
        ```
      DOC

      # this allows us to use build_essential without setting a name
      property :name, String, default: ""

      property :raise_if_unsupported, [TrueClass, FalseClass],
        description: "Raise a hard error on platforms where this resource is unsupported.",
        introduced: "15.5",
        default: false, desired_state: false # FIXME: make this default to true

      action :install, description: "Install build essential packages." do
        case
        when debian?
          package %w{ autoconf binutils-doc bison build-essential flex gettext ncurses-dev }
        when fedora_derived?
          package %w{ autoconf bison flex gcc gcc-c++ gettext kernel-devel make m4 ncurses-devel patch }
        when freebsd?
          package "devel/gmake"
          package "devel/autoconf"
          package "devel/m4"
          package "devel/gettext"
        when macos?
          install_xcode_cli_tools(xcode_cli_package_label) unless xcode_cli_installed?
        when omnios?
          package "developer/gcc48"
          package "developer/object-file"
          package "developer/linker"
          package "developer/library/lint"
          package "developer/build/gnu-make"
          package "system/header"
          package "system/library/math/header-math"

          # Per OmniOS documentation, the gcc bin dir isn't in the default
          # $PATH, so add it to the running process environment
          # http://omnios.omniti.com/wiki.php/DevEnv
          ENV["PATH"] = "#{ENV["PATH"]}:/opt/gcc-4.7.2/bin"
        when solaris2?
          package "autoconf"
          package "automake"
          package "bison"
          package "gnu-coreutils"
          package "flex"
          package "gcc"
          package "gnu-grep"
          package "gnu-make"
          package "gnu-patch"
          package "gnu-tar"
          package "make"
          package "pkg-config"
          package "ucb"
        when smartos?
          package "autoconf"
          package "binutils"
          package "build-essential"
          package "gcc47"
          package "gmake"
          package "pkg-config"
        when suse?
          package %w{ autoconf bison flex gcc gcc-c++ kernel-default-devel make m4 }
        else
          msg = <<-EOH
        The build_essential resource does not currently support the '#{node["platform_family"]}'
        platform family. Skipping...
          EOH
          if new_resource.raise_if_unsupported
            raise msg
          else
            Chef::Log.warn msg
          end
        end
      end

      action :upgrade, description: "Upgrade the Xcode CLI Tools on macOS hosts. **New in Chef Infra Client 16**" do

        if macos?
          pkg_label = xcode_cli_package_label

          # With upgrade action we should install if it's not installed or if there's an available update.
          # `pkg_label` will be nil if there's no update.
          install_xcode_cli_tools(pkg_label) if !xcode_cli_installed? || pkg_label
        else
          Chef::Log.info "The build_essential resource :upgrade action is only supported on macOS systems. Skipping..."
        end
      end

      action_class do
        #
        # Install Xcode Command Line tools via softwareupdate CLI
        #
        # @param [String] label The label (package name) to install
        #
        def install_xcode_cli_tools(label)
          # This script was graciously borrowed and modified from Tim Sutton's
          # osx-vm-templates at https://github.com/timsutton/osx-vm-templates/blob/b001475df54a9808d3d56d06e71b8fa3001fff42/scripts/xcode-cli-tools.sh
          bash "install Xcode Command Line Tools" do
            code <<-EOH
              # create the placeholder file that's checked by CLI updates' .dist code
              # in Apple's SUS catalog
              touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
              # install it
              softwareupdate -i "#{label}" --verbose
              # Remove the placeholder to prevent perpetual appearance in the update utility
              rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
            EOH
          end
        end

        #
        # Determine if the XCode Command Line Tools are installed by checking
        # for success from `xcode-select -p`
        #
        # @return [true, false]
        def xcode_cli_installed?
          !shell_out("xcode-select", "-p").error?
        end

        #
        # Return to package label of the latest Xcode Command Line Tools update, if available
        #
        # @return [String, NilClass]
        def xcode_cli_package_label
          available_updates = shell_out("softwareupdate", "--list")

          # raise if we fail to check
          available_updates.error!

          # https://rubular.com/r/UPEE5P7mZLvXNs
          # this will return the match or nil
          available_updates.stdout[/^\s*\* (?:Label: )?(Command Line Tools.*)/, 1]
        end
      end
    end
  end
end
