#
# Author:: Deepali Jagtap
# Copyright:: Copyright 2013-2016, Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
require "chef/provider/package"
require "chef/mixin/command"
require "chef/resource/package"
require "chef/mixin/get_source_from_package"

class Chef
  class Provider
    class Package
      class Aix < Chef::Provider::Package

        provides :package, os: "aix"
        provides :bff_package, os: "aix"

        include Chef::Mixin::GetSourceFromPackage

        def define_resource_requirements
          super
          requirements.assert(:install) do |a|
            a.assertion { new_resource.source }
            a.failure_message Chef::Exceptions::Package, "Source for package #{new_resource.name} required for action install"
          end
          requirements.assert(:all_actions) do |a|
            a.assertion { !new_resource.source || @package_source_found }
            a.failure_message Chef::Exceptions::Package, "Package #{new_resource.name} not found: #{new_resource.source}"
            a.whyrun "would assume #{new_resource.source} would be have previously been made available"
          end
        end

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)

          file_sets = []

          if @new_resource.source
            @package_source_found = ::File.exists?(@new_resource.source)
            if @package_source_found
              Chef::Log.debug("#{@new_resource} checking pkg status")
              src_version, file_sets = filter_source_device { |fs| file_sets << fs }
              raise Chef::Exceptions::Package, "package source #{new_resource.source} does not provide package #{new_resource.package_name}" unless src_version
              new_resource.version(src_version)
            end
          end

          Chef::Log.debug("#{@new_resource} checking install state")
          installed_file_sets = []
          ret = shell_out_with_timeout("lslpp -lcq | grep :#{@current_resource.package_name}")
          ret.stdout.each_line do |line|
            case line
            when /#{@current_resource.package_name}/
              fields = line.split(":")
              Chef::Log.debug("#{@new_resource} version #{fields[2]} is already installed")
              installed_file_sets.push([fields[1], fields[2]])
            end
          end

          # there can be multiple filesets in a package and nodes may
          # install filesets individually. We consider a package to
          # be installed only if all filesets of the source package
          # are installed and they are all at the same version
          if installed_file_sets.length > 0
            # filter out filesets that are not part of the source package
            installed_file_sets.select! { |fs| file_sets.empty? || file_sets.include?(fs[0]) }
            # if fileset versions are mixed, we dont consider the package to be installed
            if installed_file_sets.map { |fs| fs[1] }.uniq.length == 1
              # package must have all filesets
              if file_sets.empty? || installed_file_sets.map { |fs| fs[0] }.uniq.sort == file_sets
                @current_resource.version(installed_file_sets[0][1])
              end
            end
          end

          unless ret.exitstatus == 0 || ret.exitstatus == 1
            raise Chef::Exceptions::Package, "lslpp failed - #{ret.format_for_exception}!"
          end

          @current_resource
        end

        def candidate_version
          @candidate_version ||= begin
            candidate, _ = filter_source_device
            if candidate
              @candidate_version = candidate
              @new_resource.version(candidate)
              Chef::Log.debug("#{@new_resource} setting install candidate version to #{@candidate_version}")
            end
          end
        end

        #
        # The install/update action needs to be tested with various kinds of packages
        # on AIX viz. packages with or without licensing file dependencies, packages
        # with dependencies on other packages which will help to test additional
        # options of installp.
        # So far, the code has been tested only with standalone packages.
        #
        def install_package(name, version)
          Chef::Log.debug("#{@new_resource} package install options: #{@new_resource.options}")
          if @new_resource.options.nil?
            shell_out_with_timeout!( "installp -aYF -d #{@new_resource.source} #{@new_resource.package_name}" )
            Chef::Log.debug("#{@new_resource} installed version #{@new_resource.version} from: #{@new_resource.source}")
          else
            shell_out_with_timeout!( "installp -aYF #{expand_options(@new_resource.options)} -d #{@new_resource.source} #{@new_resource.package_name}" )
            Chef::Log.debug("#{@new_resource} installed version #{@new_resource.version} from: #{@new_resource.source}")
          end
        end

        alias_method :upgrade_package, :install_package

        def remove_package(name, version)
          if @new_resource.options.nil?
            shell_out_with_timeout!( "installp -u #{name}" )
            Chef::Log.debug("#{@new_resource} removed version #{@new_resource.version}")
          else
            shell_out_with_timeout!( "installp -u #{expand_options(@new_resource.options)} #{name}" )
            Chef::Log.debug("#{@new_resource} removed version #{@new_resource.version}")
          end
        end

        def filter_source_device
          return unless  new_resource.source

          file_sets = []
          ret = shell_out_with_timeout("installp -L -d #{new_resource.source}")
          unless ret.exitstatus == 0
            raise Chef::Exceptions::Package, "installp -L -d #{@new_resource.source} - #{ret.format_for_exception}!"
          end
          ret.stdout.each_line do |line|
            case line
            when /(^|:)#{new_resource.package_name}:/
              fields = line.split(":")
              file_sets.push([fields[1], fields[2]])
            end
          end

          unless file_sets.empty?
            resource_version = greatest_version(file_sets)

            # only include file sets of the latest version
            # remove the version and sort the file sets by name
            file_sets = file_sets.each_with_object([]) do |fileset, filtered|
              filtered.push(fileset[0]) if fileset[1] == resource_version
            end.uniq.sort

            [resource_version, file_sets]
          end
        end

        def greatest_version(filesets)
          sorted = filesets.sort do |x, y|
            Gem::Version.new(x[1]) <=> Gem::Version.new(y[1])
          end
          sorted.last[1]
        end
      end
    end
  end
end
