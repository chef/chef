#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'chef/provider/package'
require 'chef/mixin/command'
require 'chef/resource/package'
require 'singleton'
require 'chef/mixin/get_source_from_package'

# Declare the class for the benefit of subclasses
class Chef::Provider::Package::Yum < Chef::Provider::Package
end

require 'chef/provider/package/yum/rpm_utils'
require 'chef/provider/package/yum/rpm_version'
require 'chef/provider/package/yum/rpm_package'
require 'chef/provider/package/yum/rpm_dependency'
require 'chef/provider/package/yum/rpm_db'
require 'chef/provider/package/yum/yum_cache'

class Chef
  class Provider
    class Package
      class Yum < Chef::Provider::Package
        include Chef::Mixin::Command
        include Chef::Mixin::GetSourceFromPackage

        def initialize(new_resource, run_context)
          super

          @yum = YumCache.instance
        end

        # Extra attributes
        #

        def arch
          if @new_resource.respond_to?("arch")
            @new_resource.arch
          else
            nil
          end
        end

        def flush_cache
          if @new_resource.respond_to?("flush_cache")
            @new_resource.flush_cache
          else
            { :before => false, :after => false }
          end
        end

        def allow_downgrade
          if @new_resource.respond_to?("allow_downgrade")
            @new_resource.allow_downgrade
          else
            false
          end
        end

        # Helpers
        #

        def yum_arch
          arch ? ".#{arch}" : nil
        end

        def yum_command(command)
          status, stdout, stderr = output_of_command(command, {})

          # This is fun: rpm can encounter errors in the %post/%postun scripts which aren't
          # considered fatal - meaning the rpm is still successfully installed. These issue
          # cause yum to emit a non fatal warning but still exit(1). As there's currently no
          # way to suppress this behavior and an exit(1) will break a Chef run we make an
          # effort to trap these and re-run the same install command - it will either fail a
          # second time or succeed.
          #
          # A cleaner solution would have to be done in python and better hook into
          # yum/rpm to handle exceptions as we see fit.
          if status.exitstatus == 1
            stdout.each_line do |l|
              # rpm-4.4.2.3 lib/psm.c line 2182
              if l =~ %r{^error: %(post|postun)\(.*\) scriptlet failed, exit status \d+$}
                Chef::Log.warn("#{@new_resource} caught non-fatal scriptlet issue: \"#{l}\". Can't trust yum exit status " +
                               "so running install again to verify.")
                status, stdout, stderr = output_of_command(command, {})
                break
              end
            end
          end

          if status.exitstatus > 0
            command_output = "STDOUT: #{stdout}"
            command_output << "STDERR: #{stderr}"
            handle_command_failures(status, command_output, {})
          end
        end

        # Standard Provider methods for Parent
        #

        def load_current_resource
          if flush_cache[:before]
            @yum.reload
          end

          # At this point package_name could be:
          # 
          # 1) a package name, eg: "foo"
          # 2) a package name.arch, eg: "foo.i386"
          # 3) or a dependency, eg: "foo >= 1.1"

          # Check if we have name or name+arch which has a priority over a dependency
          unless @yum.package_available?(@new_resource.package_name)
            # If they aren't in the installed packages they could be a dependency
            parse_dependency
          end

          # Don't overwrite an existing arch
          unless arch
            parse_arch
          end

          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)

          if @new_resource.source
            unless ::File.exists?(@new_resource.source)
              raise Chef::Exceptions::Package, "Package #{@new_resource.name} not found: #{@new_resource.source}"
            end

            Chef::Log.debug("#{@new_resource} checking rpm status")
            status = shell_out!("rpm -qp --queryformat '%{NAME} %{VERSION}-%{RELEASE}\n' #{@new_resource.source}")
            status.stdout.each do |line|
              case line
              when /([\w\d_.-]+)\s([\w\d_.-]+)/
                @current_resource.package_name($1)
                @new_resource.version($2)
              end
            end
          end

          if @new_resource.version
            new_resource = "#{@new_resource.package_name}-#{@new_resource.version}#{yum_arch}"
          else
            new_resource = "#{@new_resource.package_name}#{yum_arch}"
          end

          Chef::Log.debug("#{@new_resource} checking yum info for #{new_resource}")

          installed_version = @yum.installed_version(@new_resource.package_name, arch)
          @current_resource.version(installed_version)

          @candidate_version = @yum.candidate_version(@new_resource.package_name, arch)

          Chef::Log.debug("#{@new_resource} installed version: #{installed_version || "(none)"} candidate version: " +
                          "#{@candidate_version || "(none)"}")

          @current_resource
        end

        def install_package(name, version)
          if @new_resource.source
            yum_command("yum -d0 -e0 -y#{expand_options(@new_resource.options)} localinstall #{@new_resource.source}")
          else
            # Work around yum not exiting with an error if a package doesn't exist for CHEF-2062
            if @yum.version_available?(name, version, arch)
              method = "install"
              log_method = "installing"

              # More Yum fun:
              #
              # yum install of an old name+version will exit(1)
              # yum install of an old name+version+arch will exit(0) for some reason
              #
              # Some packages can be installed multiple times like the kernel
              unless @yum.allow_multi_install.include?(name)
                if RPMVersion.parse(@current_resource.version) > RPMVersion.parse(version)
                  # Unless they want this...
                  if allow_downgrade
                    method = "downgrade"
                    log_method = "downgrading"
                  else
                    # we bail like yum when the package is older
                    raise Chef::Exceptions::Package, "Installed package #{name}-#{@current_resource.version} is newer " +
                                                     "than candidate package #{name}-#{version}"
                  end
                end
              end

              repo = @yum.package_repository(name, version, arch)
              Chef::Log.info("#{@new_resource} #{log_method} #{name}-#{version}#{yum_arch} from #{repo} repository")

              yum_command("yum -d0 -e0 -y#{expand_options(@new_resource.options)} #{method} #{name}-#{version}#{yum_arch}")
            else
              raise Chef::Exceptions::Package, "Version #{version} of #{name} not found. Did you specify both version " +
                                               "and release? (version-release, e.g. 1.84-10.fc6)"
            end
          end

          if flush_cache[:after]
            @yum.reload
          else
            @yum.reload_installed
          end
        end

        # Keep upgrades from trying to install an older candidate version. Can happen when a new
        # version is installed then removed from a repository, now the older available version
        # shows up as a viable install candidate.
        #
        # Can be done in upgrade_package but an upgraded from->to log message slips out
        #
        # Hacky - better overall solution? Custom compare in Package provider?
        def action_upgrade
          # Could be uninstalled or have no candidate
          if @current_resource.version.nil? || candidate_version.nil? 
            super
          # Ensure the candidate is newer
          elsif RPMVersion.parse(candidate_version) > RPMVersion.parse(@current_resource.version)
            super
          else
            Chef::Log.debug("#{@new_resource} is at the latest version - nothing to do")
          end
        end

        def upgrade_package(name, version)
          install_package(name, version)
        end

        def remove_package(name, version)
          if version
            yum_command("yum -d0 -e0 -y#{expand_options(@new_resource.options)} remove #{name}-#{version}#{yum_arch}")
          else
            yum_command("yum -d0 -e0 -y#{expand_options(@new_resource.options)} remove #{name}#{yum_arch}")
          end

          if flush_cache[:after]
            @yum.reload
          else
            @yum.reload_installed
          end
        end

        def purge_package(name, version)
          remove_package(name, version)
        end

        private

        def parse_arch
          # Allow for foo.x86_64 style package_name like yum uses in it's output
          #
          if @new_resource.package_name =~ %r{^(.*)\.(.*)$}
            new_package_name = $1
            new_arch = $2
            # foo.i386 and foo.beta1 are both valid package names or expressions of an arch.
            # Ensure we don't have an existing package matching package_name, then ensure we at
            # least have a match for the new_package+new_arch before we overwrite. If neither
            # then fall through to standard package handling.
            if (@yum.installed_version(@new_resource.package_name).nil? and @yum.candidate_version(@new_resource.package_name).nil?) and
                 (@yum.installed_version(new_package_name, new_arch) or @yum.candidate_version(new_package_name, new_arch))
               @new_resource.package_name(new_package_name)
               @new_resource.arch(new_arch)
            end
          end
        end

        # If we don't have the package we could have been passed a 'whatprovides' feature
        #
        # eg: yum install "perl(Config)"
        #     yum install "mtr = 2:0.71-3.1"
        #     yum install "mtr > 2:0.71"
        #
        # We support resolving these out of the Provides data imported from yum-dump.py and
        # matching them up with an actual package so the standard resource handling can apply.
        #
        # There is currently no support for filename matching.
        def parse_dependency
          # Transform the package_name into a requirement
          yum_require = RPMRequire.parse(@new_resource.package_name)
          # and gather all the packages that have a Provides feature satisfying the requirement.
          # It could be multiple be we can only manage one
          packages = @yum.packages_from_require(yum_require)

          if packages.empty?
            # Don't bother if we are just ensuring a package is removed - we don't need Provides data
            actions = Array(@new_resource.action)
            unless actions.size == 1 and (actions[0] == :remove || actions[0] == :purge)
              Chef::Log.debug("#{@new_resource} couldn't match #{@new_resource.package_name} in " +
                            "installed Provides, loading available Provides - this may take a moment")
              @yum.reload_provides
              packages = @yum.packages_from_require(yum_require)
            end
          end

          unless packages.empty?
            new_package_name = packages.first.name
            Chef::Log.debug("#{@new_resource} no package found for #{@new_resource.package_name} " +
                            "but matched Provides for #{new_package_name}")

            # Ensure it's not the same package under a different architecture
            unique_names = []
            packages.each do |pkg|
              unique_names << "#{pkg.name}-#{pkg.version.evr}"
            end
            unique_names.uniq!

            if unique_names.size > 1
              Chef::Log.warn("#{@new_resource} matched multiple Provides for #{@new_resource.package_name} " +
                             "but we can only use the first match: #{new_package_name}. Please use a more " +
                             "specific version.")
            end

            @new_resource.package_name(new_package_name)
          end
        end

      end
    end
  end
end
