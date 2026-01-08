#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
# This uses class variables on purpose to maintain a state cache between resources,
# since they work on shared state
#
# rubocop:disable Style/ClassVars

require_relative "../package"
require_relative "../../resource/chocolatey_package"
require_relative "../../win32/api/command_line_helper" if ChefUtils.windows?
require "zip" unless defined?(Zip)

class Chef
  class Provider
    class Package
      class Chocolatey < Chef::Provider::Package
        include Chef::ReservedNames::Win32::API::CommandLineHelper if ChefUtils.windows?

        provides :chocolatey_package
        # Declare that our arguments should be arrays
        use_multipackage_api

        PATHFINDING_POWERSHELL_COMMAND = "[System.Environment]::GetEnvironmentVariable('ChocolateyInstall', 'MACHINE')".freeze
        CHOCO_MISSING_MSG = <<~EOS.freeze
          Could not locate your Chocolatey install. To install chocolatey, we recommend
          the 'chocolatey_installer' resource.
          If Chocolatey is installed, ensure that the 'ChocolateyInstall' environment
          variable is correctly set. You can verify this with the PowerShell command
          '#{PATHFINDING_POWERSHELL_COMMAND}'.
        EOS

        # initialize our cache on load
        @@choco_available_packages = nil
        @@choco_config = nil

        # Responsible for building the current_resource.
        #
        # @return [Chef::Resource::ChocolateyPackage] the current_resource
        def load_current_resource
          @current_resource = Chef::Resource::ChocolateyPackage.new(new_resource.name)
          current_resource.package_name(new_resource.package_name)
          current_resource.version(build_current_versions)
          # Ensure that we have a working chocolatey executable - this used to be
          # covered off by loading the resource, but since that's no longer required,
          # we're going to put a quick check here to fail early!
          choco_exe
          current_resource
        end

        def define_resource_requirements
          super

          # The check that Chocolatey is installed is in #choco_exe.

          # Chocolatey source property points to an alternate feed
          # and not a package specific alternate source like other providers
          # so we want to assert candidates exist for the alternate source
          requirements.assert(:upgrade, :install) do |a|
            a.assertion { candidates_exist_for_all_uninstalled? }
            a.failure_message Chef::Exceptions::Package, "No candidate version available for #{packages_missing_candidates.join(", ")}"
            a.whyrun("Assuming a repository that offers #{packages_missing_candidates.join(", ")} would have been configured")
          end

          requirements.assert(:all_actions) do |a|
            a.assertion { !new_resource.environment }
            a.failure_message Chef::Exceptions::Package, "The environment property is not supported for package resources on this platform"
          end
        end

        # Lazy initializer for candidate_version.  A nil value means that there is no candidate
        # version and the package is not installable (generally an error).
        #
        # @return [Array] list of candidate_versions indexed same as new_resource.package_name/version
        def candidate_version
          @candidate_version ||= build_candidate_versions
        end

        # Install multiple packages via choco.exe
        #
        # @param names [Array<String>] array of package names to install
        # @param versions [Array<String>] array of versions to install
        def install_package(names, versions)
          name_versions_to_install = desired_name_versions.select { |n, v| lowercase_names(names).include?(n) }

          name_nil_versions = name_versions_to_install.select { |n, v| v.nil? }
          name_has_versions = name_versions_to_install.compact

          # choco does not support installing multiple packages with version pins
          name_has_versions.each do |name, version|
            choco_command("install", "-y", "--version", version, cmd_args, name)
          end

          # but we can do all the ones without version pins at once
          unless name_nil_versions.empty?
            cmd_names = name_nil_versions.keys
            choco_command("install", "-y", cmd_args, *cmd_names)
          end
        end

        # Upgrade multiple packages via choco.exe
        #
        # @param names [Array<String>] array of package names to install
        # @param versions [Array<String>] array of versions to install
        def upgrade_package(names, versions)
          name_versions_to_install = desired_name_versions.select { |n, v| lowercase_names(names).include?(n) }

          name_nil_versions = name_versions_to_install.select { |n, v| v.nil? }
          name_has_versions = name_versions_to_install.compact

          # choco does not support installing multiple packages with version pins
          name_has_versions.each do |name, version|
            choco_command("upgrade", "-y", "--version", version, cmd_args, name)
          end

          # but we can do all the ones without version pins at once
          unless name_nil_versions.empty?
            cmd_names = name_nil_versions.keys
            choco_command("upgrade", "-y", cmd_args, *cmd_names)
          end
        end

        # Remove multiple packages via choco.exe
        #
        # @param names [Array<String>] array of package names to install
        # @param versions [Array<String>] array of versions to install
        def remove_package(names, versions)
          choco_command("uninstall", "-y", cmd_args(include_source: false), *names)
        end

        # Choco does not have dpkg's distinction between purge and remove
        alias purge_package remove_package

        # Override the superclass check.  The semantics for our new_resource.source is not files to
        # install from, but like the rubygem provider's sources which are more like repos.
        def check_resource_semantics!; end

        def get_choco_version
          # We need a different way to get the version than by simply calling "choco --version".
          # If the license file is installed (for business customers) but not the Chocolatey.Extension (because you're using the choco resource to install it)
          # then you get a license error. This method bypasses that by getting the version from the exe directly instead of invoking it.
          # deprecated: @get_choco_version ||= powershell_exec!("#{choco_exe} --version").result
          @get_choco_version ||= powershell_exec!("Get-ItemProperty #{choco_exe} | select-object -expandproperty versioninfo | select-object -expandproperty productversion").result
        end

        # Choco V2 uses 'Search' for remote repositories and 'List' for local packages
        def query_command
          return "list" if Gem::Dependency.new("", "< 1.4.0").match?("", get_choco_version)

          "search"
        end

        # invalidate cache for testing purposes
        def invalidate_cache
          @@choco_config = nil
        end

        # This checks that the repo list has not changed between now and when we last checked
        # the cache
        def cache_is_valid?
          return false if @@choco_config.nil? || (actual_config != @@choco_config)

          true
        end

        # Find the set of packages to ask the chocolatey server about
        #
        # if walk_resource_tree is true, this finds _all_ of the packages that
        # we have referenced anywhere in our recipes - this is so we can
        # attempt to query them all in a single transaction.  However,
        # currently we don't do that - see the comment on available_packages
        # for details of the why, but the TL;DR is that the public chocolatey
        # servers do not support `or` type queries properly.
        #
        # If walk_resource_tree is false, we don't do any of that - we just filter
        # the package list based on cache data.  This is the default due to reasons
        # explained in the comment on available_packages - the goal is to eventually
        # turn this back on, hence the default false parameter here.
        #
        # @return [Array] List of chocolatey packages referenced in the run list
        def collect_package_requests(ignore_list: [], walk_resource_tree: false)
          return ["*"] if new_resource.bulk_query || Chef::Config[:always_use_bulk_chocolatey_package_list]

          if walk_resource_tree
            # Get to the root of the resource collection
            rc = run_context.parent_run_context || run_context
            rc = rc.parent_run_context while rc.parent_run_context

            package_collection = package_name_array
            package_collection += nested_package_resources(rc.resource_collection)
          else
            package_collection = package_name_array
          end
          # downcase the array and uniq.  sorted for easier testing...
          package_collection.uniq.sort.filter { |pkg| !ignore_list.include?(pkg) }
        end

        private

        def version_compare(v1, v2)
          if v1 == "latest" || v2 == "latest"
            return 0
          end

          gem_v1 = Gem::Version.new(v1)
          gem_v2 = Gem::Version.new(v2)

          gem_v1 <=> gem_v2
        end

        # Cache the configuration in order to ensure that we can check our
        # package cache is valid for a run
        def actual_config
          config_path = ::File.join("#{choco_install_path}", "config", "chocolatey.config")
          if ::File.exist?(config_path)
            return ::File.read(config_path)
          end

          nil
        end

        # update the validity of the package cache
        def set_package_cache
          @@choco_config = actual_config
        end

        # Magic to find where chocolatey is installed in the system, and to
        # return the full path of choco.exe
        #
        # @return [String] full path of choco.exe
        def choco_exe
          @choco_exe ||= begin
              # if this check is in #define_resource_requirements, it won't get
              # run before choco.exe gets called from #load_current_resource.
              exe_path = ::File.join(choco_install_path, "choco.exe")
              raise Chef::Exceptions::MissingLibrary, CHOCO_MISSING_MSG unless ::File.exist?(exe_path)

              exe_path
            end
        end

        # lets us mock out an incorrect value for testing.
        def choco_install_path
          @choco_install_path ||= begin
            result = powershell_exec!(PATHFINDING_POWERSHELL_COMMAND).result
            result = "" if result.empty?
            result
          end
        end

        def choco_lib_path
          ::File.join(choco_install_path, "lib")
        end

        # Helper to dispatch a choco command through shell_out using the timeout
        # set on the new resource, with nice command formatting.
        #
        # @param args [String] variable number of string arguments
        # @return [Mixlib::ShellOut] object returned from shell_out!
        def choco_command(*args)
          shell_out!(choco_exe, *args, returns: new_resource.returns)
        end

        # Use the available_packages Hash helper to create an array suitable for
        # using in candidate_version
        #
        # @return [Array] list of candidate_version, same index as new_resource.package_name/version
        def build_candidate_versions
          new_resource.package_name.map do |package_name|
            available_packages[package_name.downcase]
          end
        end

        # Use the installed_packages Hash helper to create an array suitable for
        # using in current_resource.version
        #
        # @return [Array] list of candidate_version, same index as new_resource.package_name/version
        def build_current_versions
          new_resource.package_name.map do |package_name|
            installed_packages[package_name.downcase]
          end
        end

        # Helper to construct Hash of names-to-versions, requested on the new_resource.
        # If new_resource.version is nil, then all values will be nil.
        #
        # @return [Hash] Mapping of requested names to versions
        def desired_name_versions
          desired_versions = new_resource.version || new_resource.package_name.map { nil }
          Hash[*lowercase_names(new_resource.package_name).zip(desired_versions).flatten]
        end

        def nested_package_resources(res)
          package_collection = []
          res.each do |child_res|
            package_collection += nested_package_resources(child_res.resources)
            next unless child_res.is_a?(Chef::Resource::ChocolateyPackage)

            package_collection += child_res.package_name.flatten
          end
          package_collection
        end

        # Helper to construct optional args out of new_resource
        #
        # @param include_source [Boolean] should the source parameter be added
        # @return [String] options from new_resource or empty string
        def cmd_args(include_source: true)
          cmd_args = new_resource.options.is_a?(String) ? command_line_to_argv_w_helper(new_resource.options) : Array(new_resource.options)
          cmd_args += common_options(include_source: include_source)
          cmd_args
        end

        # Available packages in chocolatey as a Hash of names mapped to versions
        # If pinning a package to a specific version, filter out all non matching versions
        # (names are downcased for case-insensitive matching)
        #
        # @return [Hash] name-to-version mapping of available packages
        def available_packages
          return @available_packages unless @available_packages.nil?

          # @available_packages is per object - each resource is an object, meaning if you
          # have a LOT of chocolatey package installs, then this quickly gets very slow.
          # So we use @@choco_available_packages instead - BUT it's important to ensure that
          # the cache is valid before you do this.  There are two cache items that can change:
          # a) the sources - we check this with cache_is_valid?
          if cache_is_valid? && @@choco_available_packages.is_a?(Hash) &&
              @@choco_available_packages[new_resource.list_options]

            # Ensure we have the package names, or else double check...
            need_redo = false
            package_name_array.each do |pkg|
              need_redo = true unless @@choco_available_packages[new_resource.list_options][pkg.downcase]
            end
            return @@choco_available_packages[new_resource.list_options] unless need_redo
          end
          if new_resource.list_options
            Chef::Log.info("Fetching chocolatey package list with options #{new_resource.list_options.inspect}")
          else
            Chef::Log.info("Fetching chocolatey package list")
          end

          # Only reset the array if the cache is invalid - if we're just augmenting it, don't
          # clear it
          @@choco_available_packages = {} if @@choco_available_packages.nil? || !cache_is_valid?
          if @@choco_available_packages[new_resource.list_options].nil?
            @@choco_available_packages[new_resource.list_options] = {}
          end

          # This would previously grab 25 packages at a time, which previously worked - however,
          # upstream changed and it turns out this was only working by accident - see
          # https://github.com/chocolatey/choco/issues/2116 for this.  So the TL;DR ends up
          # being that this can be re-enabled when the chocolatey server actually supports an
          # or operator.  So it makes sense to leave the logic here for this split, while we
          # work with upstream to get this to be a working feature there
          #
          # Foot guns: there is a --id-starts-with for chocolatey, which you'd think would work,
          # but that actually fails on public chocolatey as well, because it seems to do the filtering
          # locally. Which means it too will omit a lot of results (this is also corroborated by
          # the 2116 issue above).
          #
          # collect_package_requests, however, continues to be useful here because it filters
          # the already cached things from the list.  However, for now it will no longer walk the
          # resource tree until 2116 can be sorted out.  When we regain that ability, we should
          # re-evaluate this, since it does save a LOT of API requests!
          collect_package_requests(
            ignore_list: @@choco_available_packages[new_resource.list_options].keys
          ).each do |pkg_set|
            available_versions =
              begin
              cmd = [ query_command, "-r" ]

              # Chocolatey doesn't actually take a wildcard for this query, however
              # it will return all packages when using '*' as a query
              unless pkg_set == "*"
                cmd << pkg_set
              end
              cmd += common_options
              cmd.push( new_resource.list_options ) if new_resource.list_options

              Chef::Log.debug("Choco List Command: #{cmd}")

              raw = parse_list_output(*cmd)
              raw.keys.each_with_object({}) do |name, available|
                available[name] = desired_name_versions[name] || raw[name]
              end
            end
            @@choco_available_packages[new_resource.list_options].merge!(available_versions)
          end
          # Mark the cache as valid, with the required metadata
          set_package_cache
          # Why both?  So when we fail to find a package once, we don't try on every
          # retry, even though it would be reasonable to do so if queried in another
          # resource (because the chocolatey configuration may well have changed!)
          @available_packages = @@choco_available_packages[new_resource.list_options]
        end

        # Installed packages in chocolatey as a Hash of names mapped to versions
        # (names are downcased for case-insensitive matching).  Depending on the user
        # preference, we get these either from the local database, or from the choco
        # list command
        #
        # @return [Hash] name-to-version mapping of installed packages
        def installed_packages
          # Logic here must be either use_choco_list is false _and_ always_use_choco_list is
          # falsy, since the global overrides the local
          if new_resource.use_choco_list == false && !Chef::Config[:always_use_choco_list]
            installed_packages_via_disk
          else
            installed_packages_via_choco
          end
        end

        # Beginning with Choco 2.0, "list" returns local packages only while "search" returns packages from external package sources
        #
        # @return [Hash] name-to-version mapping of installed packages
        def installed_packages_via_choco
          @installed_packages ||= Hash[*parse_list_output("list", "-l", "-r").flatten]
          @installed_packages
        end

        # Return packages sourced from the local disk - because this doesn't have
        # shell out overhead, this ends up being a significant performance win
        # vs calling choco list
        #
        # @return [Hash] name-to-version mapping of installed packages
        def installed_packages_via_disk
          @installed_packages ||= begin
            targets = new_resource.name
            target_dirs = []
            # If we're using a single package name, have it at the head of the list
            # so we can get more performance.  In either case, the
            # array is filled by the call to `get_local_pkg_dirs` below - but
            # that contains all possible package folders, and so we push our
            # guess to the front as an optimization.
            target_dirs << targets.first.downcase if targets.length == 1
            if targets.is_a?(String)
              target_dirs << targets.downcase
            end
            target_dirs += get_local_pkg_dirs(choco_lib_path)
            fetch_package_versions(choco_lib_path, target_dirs, targets)
          end
        end

        # Grab the nupkg folder list
        def get_local_pkg_dirs(base_dir)
          return [] unless Dir.exist?(base_dir)

          Dir.entries(base_dir).select do |dir|
            ::File.directory?(::File.join(base_dir, dir)) && !dir.start_with?(".")
          end
        end

        # Helper to convert choco.exe list output to a Hash
        # (names are downcased for case-insensitive matching)
        #
        # @param cmd [String] command to run
        # @return [Hash] list output converted to ruby Hash
        def parse_list_output(*args)
          hash = {}
          choco_command(*args).stdout.each_line do |line|
            next if line.start_with?("Chocolatey v")

            name, version = line.split("|")
            hash[name.downcase] = version&.chomp
          end
          hash
        end

        # Helper to downcase all names in an array
        #
        # @param names [Array] original mixed case names
        # @return [Array] same names in lower case
        def lowercase_names(names)
          names.map(&:downcase)
        end

        def common_options(include_source: true)
          args = []
          args.push( [ "-source", new_resource.source ] ) if new_resource.source && include_source
          args.push( [ "--user", new_resource.user ] ) if new_resource.user
          args.push( [ "--password", new_resource.password ]) if new_resource.password
          args
        end

        # Fetch the local package versions from chocolatey
        def fetch_package_versions(base_dir, target_dirs, targets)
          pkg_versions = {}
          targets = [targets] if targets.is_a?(String)
          target_dirs.each do |dir|
            pkg_versions.merge!(get_pkg_data(::File.join(base_dir, dir)))
            # return early if we found the single package version we were looking for
            return pkg_versions if targets.length == 1 && pkg_versions[targets.first]
          end
          pkg_versions
        end

        # Grab the locally installed packages from the nupkg list
        # rather than shelling out to chocolatey
        def get_pkg_data(path)
          t = ::File.join(path, "*.nupkg").gsub("\\", "/")
          targets = Dir.glob(t)

          # Extract package version from the first nuspec file in this nupkg
          targets.each do |target|
            Zip::File.open(target) do |zip_file|
              zip_file.each do |entry|
                next unless entry.name.end_with?(".nuspec")

                f = entry.get_input_stream
                doc = REXML::Document.new(f.read.to_s)
                f.close
                id = doc.elements["package/metadata/id"]
                version = doc.elements["package/metadata/version"]
                return { id.text.to_s.downcase => version.text } if id && version
              end
            end
          end
          {}
        rescue StandardError => e
          Chef::Log.warn("Failed to get package info for #{path}: #{e}")
          {}
        end
      end
    end
  end
end
# rubocop:enable Style/ClassVars
