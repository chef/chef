
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software, Inc.
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

require "chef/config"
require "chef/provider/package"
require "chef/resource/yum_package"
require "chef/mixin/get_source_from_package"
require "chef/provider/package/yum/rpm_utils"
require "chef/provider/package/yum/yum_cache"

class Chef
  class Provider
    class Package
      class Yum < Chef::Provider::Package

        provides :package, platform_family: %w{rhel fedora}
        provides :yum_package, os: "linux"

        include Chef::Mixin::GetSourceFromPackage

        def initialize(new_resource, run_context)
          super

          @yum = YumCache.instance
          @yum.yum_binary = yum_binary
        end

        def yum_binary
          @yum_binary ||=
            begin
              yum_binary = new_resource.yum_binary if new_resource.is_a?(Chef::Resource::YumPackage)
              yum_binary ||= ::File.exist?("/usr/bin/yum-deprecated") ? "yum-deprecated" : "yum"
            end
        end

        # Extra attributes
        #

        def arch_for_name(n)
          if @new_resource.respond_to?("arch")
            @new_resource.arch
          elsif @arch
            idx = package_name_array.index(n)
            as_array(@arch)[idx]
          else
            nil
          end
        end

        def arch
          if @new_resource.respond_to?("arch")
            @new_resource.arch
          else
            nil
          end
        end

        def set_arch(arch)
          if @new_resource.respond_to?("arch")
            @new_resource.arch(arch)
          end
        end

        def flush_cache
          if @new_resource.respond_to?("flush_cache")
            @new_resource.flush_cache
          else
            { :before => false, :after => false }
          end
        end

        # Helpers
        #

        def yum_arch(arch)
          arch ? ".#{arch}" : nil
        end

        def yum_command(command)
          command = "#{yum_binary} #{command}"
          Chef::Log.debug("#{@new_resource}: yum command: \"#{command}\"")
          status = shell_out_with_timeout(command, { :timeout => Chef::Config[:yum_timeout] })

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
            status.stdout.each_line do |l|
              # rpm-4.4.2.3 lib/psm.c line 2182
              if l =~ %r{^error: %(post|postun)\(.*\) scriptlet failed, exit status \d+$}
                Chef::Log.warn("#{@new_resource} caught non-fatal scriptlet issue: \"#{l}\". Can't trust yum exit status " +
                               "so running install again to verify.")
                status = shell_out_with_timeout(command, { :timeout => Chef::Config[:yum_timeout] })
                break
              end
            end
          end

          if status.exitstatus > 0
            command_output = "STDOUT: #{status.stdout}\nSTDERR: #{status.stderr}"
            raise Chef::Exceptions::Exec, "#{command} returned #{status.exitstatus}:\n#{command_output}"
          end
        end

        def package_locked(name, version)
          islocked = false
          locked = shell_out_with_timeout!("yum versionlock")
          locked.stdout.each_line do |line|
            line_package = line.sub(/-[^-]*-[^-]*$/, "").split(":").last.strip
            if line_package == name
              islocked = true
            end
          end
          return islocked
        end

        # Standard Provider methods for Parent
        #

        def load_current_resource
          if flush_cache[:before]
            @yum.reload
          end

          if @new_resource.options
            repo_control = []
            @new_resource.options.split.each do |opt|
              if opt =~ %r{--(enable|disable)repo=.+}
                repo_control << opt
              end
            end

            if repo_control.size > 0
              @yum.enable_extra_repo_control(repo_control.join(" "))
            else
              @yum.disable_extra_repo_control
            end
          else
            @yum.disable_extra_repo_control
          end

          # At this point package_name could be:
          #
          # 1) a package name, eg: "foo"
          # 2) a package name.arch, eg: "foo.i386"
          # 3) or a dependency, eg: "foo >= 1.1"

          # Check if we have name or name+arch which has a priority over a dependency
          package_name_array.each_with_index do |n, index|
            unless @yum.package_available?(n)
              # If they aren't in the installed packages they could be a dependency
              dep = parse_dependency(n, new_version_array[index])
              if dep
                if @new_resource.package_name.is_a?(Array)
                  @new_resource.package_name(package_name_array - [n] + [dep.first])
                  @new_resource.version(new_version_array - [new_version_array[index]] + [dep.last]) if dep.last
                else
                  @new_resource.package_name(dep.first)
                  @new_resource.version(dep.last) if dep.last
                end
              end
            end
          end

          @current_resource = Chef::Resource::YumPackage.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)

          installed_version = []
          @candidate_version = []
          @arch = []
          if @new_resource.source
            unless ::File.exists?(@new_resource.source)
              raise Chef::Exceptions::Package, "Package #{@new_resource.name} not found: #{@new_resource.source}"
            end

            Chef::Log.debug("#{@new_resource} checking rpm status")
            shell_out_with_timeout!("rpm -qp --queryformat '%{NAME} %{VERSION}-%{RELEASE}\n' #{@new_resource.source}", :timeout => Chef::Config[:yum_timeout]).stdout.each_line do |line|
              case line
              when /([\w\d_.-]+)\s([\w\d_.-]+)/
                @current_resource.package_name($1)
                @new_resource.version($2)
              end
            end
            @candidate_version << @new_resource.version
            installed_version << @yum.installed_version(@current_resource.package_name, arch)
          else

            package_name_array.each_with_index do |pkg, idx|
              # Don't overwrite an existing arch
              if arch
                name, parch = pkg, arch
              else
                name, parch = parse_arch(pkg)
                # if we parsed an arch from the name, update the name
                # to be just the package name.
                if parch
                  if @new_resource.package_name.is_a?(Array)
                    @new_resource.package_name[idx] = name
                  else
                    @new_resource.package_name(name)
                    # only set the arch if it's a single package
                    set_arch(parch)
                  end
                end
              end

              if @new_resource.version
                new_resource =
                  "#{@new_resource.package_name}-#{@new_resource.version}#{yum_arch(parch)}"
              else
                new_resource = "#{@new_resource.package_name}#{yum_arch(parch)}"
              end
              Chef::Log.debug("#{@new_resource} checking yum info for #{new_resource}")
              installed_version << @yum.installed_version(name, parch)
              @candidate_version << @yum.candidate_version(name, parch)
              @arch << parch
            end
          end

          if installed_version.size == 1
            @current_resource.version(installed_version[0])
            @candidate_version = @candidate_version[0]
            @arch = @arch[0]
          else
            @current_resource.version(installed_version)
          end

          Chef::Log.debug("#{@new_resource} installed version: #{installed_version || "(none)"} candidate version: " +
                          "#{@candidate_version || "(none)"}")

          @current_resource
        end

        def install_remote_package(name, version)
          # Work around yum not exiting with an error if a package doesn't exist
          # for CHEF-2062
          all_avail = as_array(name).zip(as_array(version)).any? do |n, v|
            @yum.version_available?(n, v, arch_for_name(n))
          end
          method = log_method = nil
          methods = []
          if all_avail
            # More Yum fun:
            #
            # yum install of an old name+version will exit(1)
            # yum install of an old name+version+arch will exit(0) for some reason
            #
            # Some packages can be installed multiple times like the kernel
            as_array(name).zip(as_array(version)).each do |n, v|
              method = "install"
              log_method = "installing"
              idx = package_name_array.index(n)
              unless @yum.allow_multi_install.include?(n)
                if RPMVersion.parse(current_version_array[idx]) > RPMVersion.parse(v)
                  # We allow downgrading only in the evenit of single-package
                  # rules where the user explicitly allowed it
                  if allow_downgrade
                    method = "downgrade"
                    log_method = "downgrading"
                  else
                    # we bail like yum when the package is older
                    raise Chef::Exceptions::Package, "Installed package #{n}-#{current_version_array[idx]} is newer " +
                      "than candidate package #{n}-#{v}"
                  end
                end
              end
              # methods don't count for packages we won't be touching
              next if RPMVersion.parse(current_version_array[idx]) == RPMVersion.parse(v)
              methods << method
            end

            # We could split this up into two commands if we wanted to, but
            # for now, just don't support this.
            if methods.uniq.length > 1
              raise Chef::Exceptions::Package, "Multipackage rule #{name} has a mix of upgrade and downgrade packages. Cannot proceed."
            end

            repos = []
            pkg_string_bits = []
            as_array(name).zip(as_array(version)).each do |n, v|
              idx = package_name_array.index(n)
              a = arch_for_name(n)
              s = ""
              unless v == current_version_array[idx]
                s = "#{n}-#{v}#{yum_arch(a)}"
                repo = @yum.package_repository(n, v, a)
                repos << "#{s} from #{repo} repository"
                pkg_string_bits << s
              end
            end
            pkg_string = pkg_string_bits.join(" ")
            Chef::Log.info("#{@new_resource} #{log_method} #{repos.join(' ')}")
            yum_command("-d0 -e0 -y#{expand_options(@new_resource.options)} #{method} #{pkg_string}")
          else
            raise Chef::Exceptions::Package, "Version #{version} of #{name} not found. Did you specify both version " +
              "and release? (version-release, e.g. 1.84-10.fc6)"
          end
        end

        def install_package(name, version)
          if @new_resource.source
            yum_command("-d0 -e0 -y#{expand_options(@new_resource.options)} localinstall #{@new_resource.source}")
          else
            install_remote_package(name, version)
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
          if @current_resource.version.nil? || !candidate_version_array.any?
            super
          elsif candidate_version_array.zip(current_version_array).any? do |c, i|
                  RPMVersion.parse(c) > RPMVersion.parse(i)
                end
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
            remove_str = as_array(name).zip(as_array(version)).map do |n, v|
              a = arch_for_name(n)
              "#{[n, v].join('-')}#{yum_arch(a)}"
            end.join(" ")
          else
            remove_str = as_array(name).map do |n|
              a = arch_for_name(n)
              "#{n}#{yum_arch(a)}"
            end.join(" ")
          end
          yum_command("-d0 -e0 -y#{expand_options(@new_resource.options)} remove #{remove_str}")

          if flush_cache[:after]
            @yum.reload
          else
            @yum.reload_installed
          end
        end

        def purge_package(name, version)
          remove_package(name, version)
        end

        def lock_package(name, version)
          yum_command("-d0 -e0 -y#{expand_options(@new_resource.options)} versionlock add #{name}")
        end

        def unlock_package(name, version)
          yum_command("-d0 -e0 -y#{expand_options(@new_resource.options)} versionlock delete #{name}")
        end

        private

        def parse_arch(package_name)
          # Allow for foo.x86_64 style package_name like yum uses in it's output
          #
          if package_name =~ %r{^(.*)\.(.*)$}
            new_package_name = $1
            new_arch = $2
            # foo.i386 and foo.beta1 are both valid package names or expressions of an arch.
            # Ensure we don't have an existing package matching package_name, then ensure we at
            # least have a match for the new_package+new_arch before we overwrite. If neither
            # then fall through to standard package handling.
            old_installed = @yum.installed_version(package_name)
            old_candidate = @yum.candidate_version(package_name)
            new_installed = @yum.installed_version(new_package_name, new_arch)
            new_candidate = @yum.candidate_version(new_package_name, new_arch)
            if (old_installed.nil? && old_candidate.nil?) && (new_installed || new_candidate)
              Chef::Log.debug("Parsed out arch #{new_arch}, new package name is #{new_package_name}")
              return new_package_name, new_arch
            end
          end
          return package_name, nil
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
        def parse_dependency(name, version)
          # Transform the package_name into a requirement

          # If we are passed a version or a version constraint we have to assume it's a requirement first. If it can't be
          # parsed only yum_require.name will be set and @new_resource.version will be left intact
          if version
            require_string = "#{name} #{version}"
          else
            # Transform the package_name into a requirement, might contain a version, could just be
            # a match for virtual provides
            require_string = name
          end
          yum_require = RPMRequire.parse(require_string)
          # and gather all the packages that have a Provides feature satisfying the requirement.
          # It could be multiple be we can only manage one
          packages = @yum.packages_from_require(yum_require)

          if packages.empty?
            # Don't bother if we are just ensuring a package is removed - we don't need Provides data
            actions = Array(@new_resource.action)
            unless actions.size == 1 && (actions[0] == :remove || actions[0] == :purge)
              Chef::Log.debug("#{@new_resource} couldn't match #{@new_resource.package_name} in " +
                            "installed Provides, loading available Provides - this may take a moment")
              @yum.reload_provides
              packages = @yum.packages_from_require(yum_require)
            end
          end

          unless packages.empty?
            new_package_name = packages.first.name
            new_package_version = packages.first.version.to_s
            debug_msg = "#{name}: Unable to match package '#{name}' but matched #{packages.size} "
            debug_msg << (packages.size == 1 ? "package" : "packages")
            debug_msg << ", selected '#{new_package_name}' version '#{new_package_version}'"
            Chef::Log.debug(debug_msg)

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

            if yum_require.version.to_s.nil?
              new_package_version = nil
            end

            [new_package_name, new_package_version]
          end
        end

      end
    end
  end
end
