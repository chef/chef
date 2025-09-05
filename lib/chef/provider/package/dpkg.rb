#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Copyright:: Copyright 2009-2016, Bryan McLellan
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

require_relative "../package"
require_relative "deb"
require_relative "../../resource/package"

class Chef
  class Provider
    class Package
      class Dpkg < Chef::Provider::Package
        include Chef::Provider::Package::Deb
        DPKG_REMOVED   = /^Status: deinstall ok config-files/
        DPKG_INSTALLED = /^Status: install ok installed/
        DPKG_VERSION   = /^Version: (.+)$/

        provides :dpkg_package, target_mode: true

        use_multipackage_api
        use_package_name_for_source

        def define_resource_requirements
          super

          requirements.assert(:install, :upgrade) do |a|
            a.assertion { !resolved_source_array.compact.empty? }
            a.failure_message Chef::Exceptions::Package, "#{new_resource} the source property is required for action :install or :upgrade"
          end

          requirements.assert(:install, :upgrade) do |a|
            a.assertion { source_files_exist? }
            a.failure_message Chef::Exceptions::Package, "#{new_resource} source file(s) do not exist: #{missing_sources}"
            a.whyrun "Assuming they would have been previously created."
          end
        end

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(new_resource.name)
          current_resource.package_name(new_resource.package_name)

          if source_files_exist?
            @candidate_version = get_candidate_version
            current_resource.package_name(get_package_name)
            # if the source file exists then our package_name is right
            current_resource.version(get_current_version_from(current_package_name_array))
          elsif !installing?
            # we can't do this if we're installing with no source, because our package_name
            # is probably not right.
            #
            # if we're removing or purging we don't use source, and our package_name must
            # be right so we can do this.
            #
            # we don't error here on the dpkg command since we'll handle the exception or
            # the why-run message in define_resource_requirements.
            current_resource.version(get_current_version_from(current_package_name_array))
          end

          current_resource
        end

        def install_package(name, version)
          sources = name.map { |n| name_sources[n] }
          logger.info("#{new_resource} installing package(s): #{name.join(" ")}")
          run_noninteractive("dpkg", "-i", *options, *sources)
        end

        def remove_package(name, version)
          logger.info("#{new_resource} removing package(s): #{name.join(" ")}")
          run_noninteractive("dpkg", "-r", *options, *name)
        end

        def purge_package(name, version)
          logger.info("#{new_resource} purging packages(s): #{name.join(" ")}")
          run_noninteractive("dpkg", "-P", *options, *name)
        end

        def upgrade_package(name, version)
          install_package(name, version)
        end

        # Override the superclass check.  Multiple sources are required here.
        def check_resource_semantics!; end

        private

        # compare 2 versions to each other to see which is newer.
        # this differs from the standard package method because we
        # need to be able to parse debian version strings which contain
        # tildes which Gem cannot properly parse
        #
        # @return [Integer] 1 if v1 > v2. 0 if they're equal. -1 if v1 < v2
        def version_compare(v1, v2)
          if !shell_out("dpkg", "--compare-versions", v1.to_s, "gt", v2.to_s).error?
            1
          elsif !shell_out("dpkg", "--compare-versions", v1.to_s, "eq", v2.to_s).error?
            0
          else
            -1
          end
        end

        def read_current_version_of_package(package_name)
          logger.trace("#{new_resource} checking install state of #{package_name}")
          status = shell_out!("dpkg", "-s", package_name, returns: [0, 1])
          package_installed = false
          status.stdout.each_line do |line|
            case line
            when DPKG_REMOVED
              # if we are 'purging' then we consider 'removed' to be 'installed'
              package_installed = true if action == :purge
            when DPKG_INSTALLED
              package_installed = true
            when DPKG_VERSION
              if package_installed
                logger.trace("#{new_resource} current version is #{$1}")
                return $1
              end
            end
          end
          nil
        end

        def get_current_version_from(array)
          array.map do |name|
            read_current_version_of_package(name)
          end
        end

        # Returns true if all sources exist.  Returns false if any do not, or if no
        # sources were specified.
        #
        # @return [Boolean] True if all sources exist
        def source_files_exist?
          resolved_source_array.all? { |s| s && ::TargetIO::File.exist?(s) }
        end

        # Helper to return all the names of the missing sources for error messages.
        #
        # @return [Array<String>] Array of missing sources
        def missing_sources
          resolved_source_array.select { |s| s.nil? || !::TargetIO::File.exist?(s) }
        end

        def current_package_name_array
          [ current_resource.package_name ].flatten
        end

        # Helper to construct Hash of names-to-sources.
        #
        # @return [Hash] Mapping of package names to sources
        def name_sources
          @name_sources ||= Hash[*package_name_array.zip(resolved_source_array).flatten]
        end

        # Helper to construct Hash of names-to-package-information.
        #
        # @return [Hash] Mapping of package names to package information
        def name_pkginfo
          @name_pkginfo ||=
            begin
              pkginfos = resolved_source_array.map do |src|
                logger.trace("#{new_resource} checking #{src} dpkg status")
                status = shell_out!("dpkg-deb", "-W", src)
                status.stdout
              end
              Hash[*package_name_array.zip(pkginfos).flatten]
            end
        end

        def name_candidate_version
          @name_candidate_version ||= name_pkginfo.transform_values { |v| v ? v.split("\t")[1]&.strip : nil }
        end

        def name_package_name
          @name_package_name ||= name_pkginfo.transform_values { |v| v ? v.split("\t")[0] : nil }
        end

        # Return candidate version array from pkg-deb -W against the source file(s).
        #
        # @return [Array] Array of candidate versions read from the source files
        def get_candidate_version
          package_name_array.map { |name| name_candidate_version[name] }
        end

        # Return package names from the candidate source file(s).
        #
        # @return [Array] Array of actual package names read from the source files
        def get_package_name
          package_name_array.map { |name| name_package_name[name] }
        end

        # Since upgrade just calls install, this is a helper to determine
        # if our action means that we'll be calling install_package.
        #
        # @return [Boolean] true if we're doing :install or :upgrade
        def installing?
          %i{install upgrade}.include?(action)
        end

      end
    end
  end
end
