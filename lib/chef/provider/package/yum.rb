
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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
        include Chef::Mixin::GetSourceFromPackage

        provides :package, platform_family: %w{rhel fedora amazon}
        provides :yum_package, os: "linux"

        # Multipackage API
        allow_nils
        use_multipackage_api
        use_package_name_for_source

        # Overload the Package provider to keep track of the YumCache
        def initialize(new_resource, run_context)
          super

          @yum = YumCache.instance
          @yum.yum_binary = yum_binary
        end

        # @see Chef::Provider::Package#check_resource_semantics!
        def check_resource_semantics!
          super

          if !new_resource.version.nil? && package_name_array.length != new_version_array.length
            raise Chef::Exceptions::InvalidResourceSpecification, "Please provide a version for each package. Use `nil` for default version."
          end

          if !new_resource.arch.nil? && package_name_array.length != safe_arch_array.length
            raise Chef::Exceptions::InvalidResourceSpecification, "Please provide an architecture for each package. Use `nil` for default architecture."
          end
        end

        # @see Chef::Provider#define_resource_requirements
        def define_resource_requirements
          super

          # Ensure that the source file (if specified) is present on the file system
          requirements.assert(:install, :upgrade, :remove, :purge) do |a|
            a.assertion { !new_resource.source || ::File.exist?(new_resource.source) }
            a.failure_message Chef::Exceptions::Package, "Package #{new_resource.package_name} not found: #{new_resource.source}"
            a.whyrun "assuming #{new_resource.source} would have previously been created"
          end
        end

        # @see Chef::Provider#load_current_resource
        def load_current_resource
          @yum.reload if flush_cache[:before]
          manage_extra_repo_control

          if new_resource.source
            query_source_file
          else
            # At this point package_name could be:
            #
            # 1) a package name, eg: "foo"
            # 2) a package name.arch, eg: "foo.i386"
            # 3) or a dependency, eg: "foo >= 1.1"
            #
            # In the third case, we want to convert those dependency strings into
            # packages that we can actually install
            convert_dependency_strings_into_packages

            # Fill out the rest of the details by querying the Yum Cache
            query_yum_cache
          end

          @current_resource = Chef::Resource::YumPackage.new(new_resource.name)
          current_resource.package_name(new_resource.package_name)
          current_resource.version(@installed_version)
          current_resource
        end

        # @see Chef::Provider::Package#package_locked
        def package_locked(name, version)
          islocked = false
          locked = shell_out_with_timeout!("yum versionlock")
          locked.stdout.each_line do |line|
            line_package = line.sub(/-[^-]*-[^-]*$/, "").split(":").last.strip
            if line_package == name
              islocked = true
            end
          end
          islocked
        end

        #
        # Package Action Classes
        #

        # @see Chef::Provider::Package#install_package
        def install_package(name, version)
          if new_resource.source
            yum_command("-d0 -e0 -y#{expand_options(new_resource.options)} localinstall #{new_resource.source}")
          else
            install_remote_package(name, version)
          end

          flush_cache[:after] ? @yum.reload : @yum.reload_installed
        end

        # @see Chef::Provider::Package#upgrade_package
        def upgrade_package(name, version)
          install_package(name, version)
        end

        # @see Chef::Provider::Package#remove_package
        def remove_package(name, version)
          remove_str = full_package_name(name, version).join(" ")
          yum_command("-d0 -e0 -y#{expand_options(new_resource.options)} remove #{remove_str}")

          flush_cache[:after] ? @yum.reload : @yum.reload_installed
        end

        # @see Chef::Provider::Package#purge_package
        def purge_package(name, version)
          remove_package(name, version)
        end

        # @see Chef::Provider::Package#lock_package
        def lock_package(name, version)
          lock_str = full_package_name(name, as_array(name).map { nil }).join(" ")
          yum_command("-d0 -e0 -y#{expand_options(new_resource.options)} versionlock add #{lock_str}")
        end

        # @see Chef::Provider::Package#unlock_package
        def unlock_package(name, version)
          unlock_str = full_package_name(name, as_array(name).map { nil }).join(" ")
          yum_command("-d0 -e0 -y#{expand_options(new_resource.options)} versionlock delete #{unlock_str}")
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
          if current_resource.version.nil? || !candidate_version_array.any?
            super
          elsif candidate_version_array.zip(current_version_array).any? do |c, i|
                  RPMVersion.parse(c) > RPMVersion.parse(i)
                end
            super
          else
            Chef::Log.debug("#{new_resource} is at the latest version - nothing to do")
          end
        end

        private

        #
        # System Level Yum Operations
        #

        def yum_binary
          @yum_binary ||=
            begin
              yum_binary = new_resource.yum_binary if new_resource.is_a?(Chef::Resource::YumPackage)
              yum_binary ||= ::File.exist?("/usr/bin/yum-deprecated") ? "yum-deprecated" : "yum"
            end
        end

        # Enable or disable YumCache extra_repo_control
        def manage_extra_repo_control
          if new_resource.options
            repo_control = []
            new_resource.options.each do |opt|
              repo_control << opt if opt =~ /--(enable|disable)repo=.+/
            end

            if !repo_control.empty?
              @yum.enable_extra_repo_control(repo_control.join(" "))
            else
              @yum.disable_extra_repo_control
            end
          else
            @yum.disable_extra_repo_control
          end
        end

        # Query the Yum cache for information about potential packages
        def query_yum_cache
          installed_versions = []
          candidate_versions = []

          package_name_array.each_with_index do |n, idx|
            pkg_name, eval_pkg_arch = parse_arch(n)

            # Defer to the arch property for the desired package architecture
            pkg_arch = safe_arch_array[idx] || eval_pkg_arch
            set_package_name(idx, pkg_name)
            set_package_arch(idx, pkg_arch)

            Chef::Log.debug("#{new_resource} checking yum info for #{yum_syntax(n, nil, pkg_arch)}")
            installed_versions << iv = @yum.installed_version(pkg_name, pkg_arch)
            candidate_versions << cv = @yum.candidate_version(pkg_name, pkg_arch)

            Chef::Log.debug("Found Yum package: #{pkg_name} installed version: #{iv || '(none)'} candidate version: #{cv || '(none)'}")
          end

          @installed_version = installed_versions.length > 1 ? installed_versions : installed_versions[0]
          @candidate_version = candidate_versions.length > 1 ? candidate_versions : candidate_versions[0]
        end

        # Query the provided source file for the package name and version
        def query_source_file
          Chef::Log.debug("#{new_resource} checking rpm status")
          shell_out_with_timeout!("rpm -qp --queryformat '%{NAME} %{VERSION}-%{RELEASE} %{ARCH}\n' #{new_resource.source}", timeout: Chef::Config[:yum_timeout]).stdout.each_line do |line|
            case line
            when /^(\S+)\s(\S+)\s(\S+)$/
              n = $1
              v = $2
              a = $3

              unless new_resource.package_name == n
                Chef::Log.debug("#{new_resource} updating package_name from #{new_resource.package_name} to #{n} (per #{new_resource.source})")
                new_resource.package_name(n)
              end

              unless new_resource.version == v
                Chef::Log.debug("#{new_resource} updating version from #{new_resource.version} to #{v} (per #{new_resource.source})")
                new_resource.version(v)
              end

              unless new_resource.arch == a
                Chef::Log.debug("#{new_resource} updating architecture from #{new_resource.arch} to #{a} (per #{new_resource.source})")
                new_resource.arch(a)
              end
            end
          end

          @installed_version = @yum.installed_version(new_resource.package_name, new_resource.arch)
          @candidate_version = new_resource.version
        end

        def yum_command(command)
          command = "#{yum_binary} #{command}"
          Chef::Log.debug("#{new_resource}: yum command: \"#{command}\"")
          status = shell_out_with_timeout(command, timeout: Chef::Config[:yum_timeout])

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
              next unless l =~ /^error: %(post|postun)\(.*\) scriptlet failed, exit status \d+$/
              Chef::Log.warn("#{new_resource} caught non-fatal scriptlet issue: \"#{l}\". Can't trust yum exit status " \
                             "so running install again to verify.")
              status = shell_out_with_timeout(command, timeout: Chef::Config[:yum_timeout])
              break
            end
          end

          if status.exitstatus > 0
            command_output = "STDOUT: #{status.stdout}\nSTDERR: #{status.stderr}"
            raise Chef::Exceptions::Exec, "#{command} returned #{status.exitstatus}:\n#{command_output}"
          end
        end

        def install_remote_package(name, version)
          # Work around yum not exiting with an error if a package doesn't exist for CHEF-2062.
          all_avail = as_array(name).zip(as_array(version), safe_arch_array).any? do |n, v, a|
            @yum.version_available?(n, v, a)
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
            as_array(name).zip(current_version_array, as_array(version), safe_arch_array).each do |n, cv, v, a|
              next if n.nil?

              method = "install"
              log_method = "installing"

              unless @yum.allow_multi_install.include?(n)
                if RPMVersion.parse(cv) > RPMVersion.parse(v)
                  # We allow downgrading only in the evenit of single-package
                  # rules where the user explicitly allowed it
                  if allow_downgrade
                    method = "downgrade"
                    log_method = "downgrading"
                  else
                    # we bail like yum when the package is older
                    raise Chef::Exceptions::Package, "Installed package #{yum_syntax(n, cv, a)} is newer " \
                      "than candidate package #{yum_syntax(n, v, a)}"
                  end
                end
              end
              # methods don't count for packages we won't be touching
              next if RPMVersion.parse(cv) == RPMVersion.parse(v)
              methods << method
            end

            # We could split this up into two commands if we wanted to, but
            # for now, just don't support this.
            if methods.uniq.length > 1
              raise Chef::Exceptions::Package, "Multipackage rule #{name} has a mix of upgrade and downgrade packages. Cannot proceed."
            end

            repos = []
            pkg_string_bits = []
            as_array(name).zip(current_version_array, as_array(version), safe_arch_array).each do |n, cv, v, a|
              next if n.nil?
              next if v == cv
              s = yum_syntax(n, v, a)
              repo = @yum.package_repository(n, v, a)
              repos << "#{s} from #{repo} repository"
              pkg_string_bits << s
            end
            pkg_string = pkg_string_bits.join(" ")
            Chef::Log.info("#{new_resource} #{log_method} #{repos.join(' ')}")
            yum_command("-d0 -e0 -y#{expand_options(new_resource.options)} #{method} #{pkg_string}")
          else
            raise Chef::Exceptions::Package, "Version #{version} of #{name} not found. Did you specify both version " \
              "and release? (version-release, e.g. 1.84-10.fc6)"
          end
        end

        # Allow for foo.x86_64 style package_name like yum uses in it's output
        def parse_arch(package_name)
          if package_name =~ /^(.*)\.(.*)$/
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
          [package_name, nil]
        end

        #
        # Dependency String Handling
        #

        # Iterate through the list of package_names given to us by the user and
        # see if any of them are in the depenency format ("foo >= 1.1"). Modify
        # the list of packages and versions to incorporate those values.
        def convert_dependency_strings_into_packages
          package_name_array.each_with_index do |n, index|
            next if @yum.package_available?(n)
            # If they aren't in the installed packages they could be a dependency.
            dep = parse_dependency(n, new_version_array[index])
            if dep
              if new_resource.package_name.is_a?(Array)
                new_resource.package_name(package_name_array - [n] + [dep.first])
                new_resource.version(new_version_array - [new_version_array[index]] + [dep.last]) if dep.last
              else
                new_resource.package_name(dep.first)
                new_resource.version(dep.last) if dep.last
              end
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
        #
        # Note: This was largely left alone during the multipackage refactor
        def parse_dependency(name, version)
          # Transform the package_name into a requirement

          # If we are passed a version or a version constraint we have to assume it's a requirement first. If it can't be
          # parsed only yum_require.name will be set and new_resource.version will be left intact
          require_string = if version
                             "#{name} #{version}"
                           else
                             # Transform the package_name into a requirement, might contain a version, could just be
                             # a match for virtual provides
                             name
                           end
          yum_require = RPMRequire.parse(require_string)
          # and gather all the packages that have a Provides feature satisfying the requirement.
          # It could be multiple be we can only manage one
          packages = @yum.packages_from_require(yum_require)

          if packages.empty?
            # Don't bother if we are just ensuring a package is removed - we don't need Provides data
            actions = Array(new_resource.action)
            unless actions.size == 1 && (actions[0] == :remove || actions[0] == :purge)
              Chef::Log.debug("#{new_resource} couldn't match #{new_resource.package_name} in " \
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
              Chef::Log.warn("#{new_resource} matched multiple Provides for #{new_resource.package_name} " \
                             "but we can only use the first match: #{new_package_name}. Please use a more " \
                             "specific version.")
            end

            if yum_require.version.to_s.nil?
              new_package_version = nil
            end

            [new_package_name, new_package_version]
          end
        end

        #
        # Misc Helpers
        #

        # Given an list of names and versions, generate the full yum syntax package name
        def full_package_name(name, version)
          as_array(name).zip(as_array(version), safe_arch_array).map do |n, v, a|
            yum_syntax(n, v, a)
          end
        end

        # Generate the yum syntax for the package
        def yum_syntax(name, version, arch)
          s = name
          s += "-#{version}" if version
          s += ".#{arch}" if arch
          s
        end

        # Set the package name correctly based on whether it is a String or Array
        def set_package_name(idx, name)
          if new_resource.package_name.is_a?(String)
            new_resource.package_name(name)
          else
            new_resource.package_name[idx] = name
          end
        end

        # Set the architecture correcly based on whether it is a String or Array
        def set_package_arch(idx, arch)
          if new_resource.package_name.is_a?(String)
            new_resource.arch(arch) unless arch.nil?
          else
            new_resource.arch ||= []
            new_resource.arch[idx] = arch
          end
        end

        # A cousin of package_name_array, return a list of the architectures
        # defined in the resource.
        def safe_arch_array
          if new_resource.arch.is_a?(Array)
            new_resource.arch
          elsif new_resource.arch.nil?
            package_name_array.map { nil }
          else
            [ new_resource.arch ]
          end
        end

        def flush_cache
          if new_resource.respond_to?("flush_cache")
            new_resource.flush_cache
          else
            { before: false, after: false }
          end
        end
      end
    end
  end
end
