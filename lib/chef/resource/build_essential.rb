#
# Copyright:: 2008-2019, Chef Software Inc.
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
      resource_name :build_essential
      provides(:build_essential) { true }

      description "Use the build_essential resource to install the packages required for compiling C software from source."
      introduced "14.0"
      examples <<~DOC
        Install compilation packages
        ```ruby
        build_essential
        ```

        Install compilation packages during the compilation phase
        ```ruby
        build_essential 'Install compilation tools' do
          compile_time true
        end
        ```
      DOC

      # this allows us to use build_essential without setting a name
      property :name, String, default: ""

      property :compile_time, [TrueClass, FalseClass],
        description: "Install the build essential packages at compile time.",
        default: false, desired_state: false

      property :raise_if_unsupported, [TrueClass, FalseClass],
        description: "Raise a hard error on platforms where this resource is unsupported.",
        default: false, desired_state: false # FIXME: make this default to true

      action :install do

        description "Install build essential packages"

        case
        when debian?
          package %w{ autoconf binutils-doc bison build-essential flex gettext ncurses-dev }
         when fedora_derived?
           package %w{ autoconf bison flex gcc gcc-c++ gettext kernel-devel make m4 ncurses-devel patch }

          # Ensure GCC 4 is available on older pre-6 EL
           package %w{ gcc44 gcc44-c++ } if platform_family?("rhel") && node["platform_version"].to_i < 6
        when freebsd?
          package "devel/gmake"
          package "devel/autoconf"
          package "devel/m4"
          package "devel/gettext"
        when macos?
          update_label = xcode_cli_package
          unless xcode_cli_installed? && update_label.empty?
            # This script was graciously borrowed and modified from Tim Sutton's
            # osx-vm-templates at https://github.com/timsutton/osx-vm-templates/blob/b001475df54a9808d3d56d06e71b8fa3001fff42/scripts/xcode-cli-tools.sh
            execute "install XCode Command Line tools" do
              command <<-EOH.gsub(/^ {14}/, "")
                # create the placeholder file that's checked by CLI updates' .dist code
                # in Apple's SUS catalog
                touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
                # find the CLI Tools update. We tail here because sometimes there's 2 and newest is last
                PROD=#{update_label}
                # install it
                softwareupdate -i "$PROD" --verbose
                # Remove the placeholder to prevent perpetual appearance in the update utility
                rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
              EOH
            end
          end
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
          package "gcc" do
            # lock because we don't use 5 yet
            version "4.8.2"
          end
          package "gcc-3"
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
          package %w{ gcc48 gcc48-c++ } if node["platform_version"].to_i < 12
        else
          if new_resource.raise_if_unsupported
            raise <<-EOH
        The build_essential resource does not currently support the '#{node["platform_family"]}'
        platform family. Skipping...
            EOH
          else
            Chef::Log.warn <<-EOH
        The build_essential resource does not currently support the '#{node["platform_family"]}'
        platform family. Skipping...
            EOH
          end
        end
      end

      action_class do
        #
        # Determine if the XCode Command Line Tools are installed
        #
        # @return [true, false]
        def xcode_cli_installed?
          cmd = Mixlib::ShellOut.new("pkgutil --pkgs=com.apple.pkg.CLTools_Executables")
          cmd.run_command
          # pkgutil returns an error if the package isn't found aka not installed
          cmd.error? ? false : true
        end

        #
        # Return to package label of the latest XCode Command Line Tools update, if available
        #
        # @return [String]
        def xcode_cli_package
          cmd = <<-EOH.gsub(/^ {14}/, "")
          softwareupdate -l | grep "\*.*Command Line" | tail -n 1 | awk -F"*" '{print $2}' | sed -e 's/^ *//' | tr -d '\n' | sed 's/Label: //g'
          EOH
          cmd.run_command
          cmd.error!
          cmd.stdout
        end
      end

      # this resource forces itself to run at compile_time
      #
      # @return [void]
      def after_created
        return unless compile_time

        Array(action).each do |action|
          run_action(action)
        end
      end
    end
  end
end
