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

require 'chef/mixin/command'
require 'chef/log'
require 'chef/file_cache'
require 'chef/platform'

class Chef
  class Provider
    class Package < Chef::Provider

      # @todo: validate no subclasses need this and nuke it
      include Chef::Mixin::Command

      #
      # Hook that subclasses use to populate the candidate_version(s)
      #
      # @return [Array, String] candidate_version(s) may be a string or array
      attr_accessor :candidate_version

      def initialize(new_resource, run_context)
        super
        @candidate_version = nil
      end

      def whyrun_supported?
        true
      end

      def load_current_resource
      end

      def define_resource_requirements
        # XXX: upgrade with a specific version doesn't make a whole lot of sense, but why don't we throw this anyway if it happens?
        # if not, shouldn't we raise to tell the user to use install instead of upgrade if they want to pin a version?
        requirements.assert(:install) do |a|
          a.assertion { candidates_exist_for_all_forced_changes? }
          a.failure_message(Chef::Exceptions::Package, "No version specified, and no candidate version available for #{forced_packages_missing_candidates.join(", ")}")
          a.whyrun("Assuming a repository that offers #{forced_packages_missing_candidates.join(", ")} would have been configured")
        end

        requirements.assert(:upgrade, :install) do |a|
          a.assertion  { candidates_exist_for_all_uninstalled? }
          a.failure_message(Chef::Exceptions::Package, "No candidate version available for #{packages_missing_candidates.join(", ")}")
          a.whyrun("Assuming a repository that offers #{packages_missing_candidates.join(", ")} would have been configured")
        end
      end

      def action_install
        unless target_version_array.any?
          Chef::Log.debug("#{@new_resource} is already installed - nothing to do")
          return
        end

        # @todo: move the preseed code out of the base class (and complete the fix for Array of preseeds? ugh...)
        if @new_resource.response_file
          if preseed_file = get_preseed_file(package_names_for_targets, versions_for_targets)
            converge_by("preseed package #{package_names_for_targets}") do
              preseed_package(preseed_file)
            end
          end
        end

        # XXX: mutating the new resource is generally bad
        @new_resource.version(versions_for_new_resource)

        converge_by(install_description) do
          install_package(package_names_for_targets, versions_for_targets)
          Chef::Log.info("#{@new_resource} installed #{package_names_for_targets} at #{versions_for_targets}")
        end
      end

      def install_description
        description = []
        target_version_array.each_with_index do |target_version, i|
          next if target_version.nil?
          package_name = package_name_array[i]
          description << "install version #{target_version} of package #{package_name}"
        end
        description
      end

      private :install_description

      def action_upgrade
        if !target_version_array.any?
          Chef::Log.debug("#{@new_resource} no versions to upgrade - nothing to do")
          return
        end

        # XXX: mutating the new resource is generally bad
        @new_resource.version(versions_for_new_resource)

        converge_by(upgrade_description) do
          upgrade_package(package_names_for_targets, versions_for_targets)
          Chef::Log.info("#{@new_resource} upgraded #{package_names_for_targets} to #{versions_for_targets}")
        end
      end

      def upgrade_description
        description = []
        target_version_array.each_with_index do |target_version, i|
          next if target_version.nil?
          package_name = package_name_array[i]
          candidate_version = candidate_version_array[i]
          current_version = current_version_array[i] || "uninstalled"
          description << "upgrade package #{package_name} from #{current_version} to #{candidate_version}"
        end
        description
      end

      private :upgrade_description

      # @todo: ability to remove an array of packages
      def action_remove
        if removing_package?
          description = @new_resource.version ? "version #{@new_resource.version} of " :  ""
          converge_by("remove #{description} package #{@current_resource.package_name}") do
            remove_package(@current_resource.package_name, @new_resource.version)
            Chef::Log.info("#{@new_resource} removed")
          end
        else
          Chef::Log.debug("#{@new_resource} package does not exist - nothing to do")
        end
      end

      def have_any_matching_version?
        f = []
        new_version_array.each_with_index do |item, index|
          f << (item == current_version_array[index])
        end
        f.any?
      end

      def removing_package?
        if !current_version_array.any?
          # ! any? means it's all nil's, which means nothing is installed
          false
        elsif !new_version_array.any?
          true # remove any version of all packages
        elsif have_any_matching_version?
          true # remove the version we have
        else
          false # we don't have the version we want to remove
        end
      end

      # @todo: ability to purge an array of packages
      def action_purge
        if removing_package?
          description = @new_resource.version ? "version #{@new_resource.version} of" : ""
          converge_by("purge #{description} package #{@current_resource.package_name}") do
            purge_package(@current_resource.package_name, @new_resource.version)
            Chef::Log.info("#{@new_resource} purged")
          end
        end
      end

      # @todo: ability to reconfigure an array of packages
      def action_reconfig
        if @current_resource.version == nil then
          Chef::Log.debug("#{@new_resource} is NOT installed - nothing to do")
          return
        end

        unless @new_resource.response_file then
          Chef::Log.debug("#{@new_resource} no response_file provided - nothing to do")
          return
        end

        if preseed_file = get_preseed_file(@new_resource.package_name, @current_resource.version)
          converge_by("reconfigure package #{@new_resource.package_name}") do
            preseed_package(preseed_file)
            reconfig_package(@new_resource.package_name, @current_resource.version)
            Chef::Log.info("#{@new_resource} reconfigured")
          end
        else
          Chef::Log.debug("#{@new_resource} preseeding has not changed - nothing to do")
        end
      end

      # @todo use composition rather than inheritance
      def install_package(name, version)
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :install"
      end

      def upgrade_package(name, version)
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :upgrade"
      end

      def remove_package(name, version)
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :remove"
      end

      def purge_package(name, version)
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :purge"
      end

      def preseed_package(file)
        raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support pre-seeding package install/upgrade instructions"
      end

      def reconfig_package(name, version)
        raise( Chef::Exceptions::UnsupportedAction, "#{self.to_s} does not support :reconfig" )
      end

      # this is heavily used by subclasses
      def expand_options(options)
        options ? " #{options}" : ""
      end

      # this is public and overridden by subclasses (rubygems package implements '>=' and '~>' operators)
      def target_version_already_installed?(current_version, new_version)
        new_version == current_version
      end

      # @todo: extract apt/dpkg specific preseeding to a helper class
      def get_preseed_file(name, version)
        resource = preseed_resource(name, version)
        resource.run_action(:create)
        Chef::Log.debug("#{@new_resource} fetched preseed file to #{resource.path}")

        if resource.updated_by_last_action?
          resource.path
        else
          false
        end
      end

      # @todo: extract apt/dpkg specific preseeding to a helper class
      def preseed_resource(name, version)
        # A directory in our cache to store this cookbook's preseed files in
        file_cache_dir = Chef::FileCache.create_cache_path("preseed/#{@new_resource.cookbook_name}")
        # The full path where the preseed file will be stored
        cache_seed_to = "#{file_cache_dir}/#{name}-#{version}.seed"

        Chef::Log.debug("#{@new_resource} fetching preseed file to #{cache_seed_to}")

        if template_available?(@new_resource.response_file)
          Chef::Log.debug("#{@new_resource} fetching preseed file via Template")
          remote_file = Chef::Resource::Template.new(cache_seed_to, run_context)
          remote_file.variables(@new_resource.response_file_variables)
        elsif cookbook_file_available?(@new_resource.response_file)
          Chef::Log.debug("#{@new_resource} fetching preseed file via cookbook_file")
          remote_file = Chef::Resource::CookbookFile.new(cache_seed_to, run_context)
        else
          message = "No template or cookbook file found for response file #{@new_resource.response_file}"
          raise Chef::Exceptions::FileNotFound, message
        end

        remote_file.cookbook_name = @new_resource.cookbook_name
        remote_file.source(@new_resource.response_file)
        remote_file.backup(false)
        remote_file
      end

      # helper method used by subclasses
      #
      def as_array(thing)
        [ thing ].flatten
      end

      private

      # Returns the package names which need to be modified.  If the resource was called with an array of packages
      # then this will return an array of packages to update (may have 0 or 1 entries).  If the resource was called
      # with a non-array package_name to manage then this will return a string rather than an Array.  The output
      # of this is meant to be fed into subclass interfaces to install/upgrade packages and not all of them are
      # Array-aware.
      #
      # @return [String, Array<String>] package_name(s) to actually update/install
      def package_names_for_targets
        package_names_for_targets = []
        target_version_array.each_with_index do |target_version, i|
          next if target_version.nil?
          package_name = package_name_array[i]
          package_names_for_targets.push(package_name)
        end
        multipackage? ? package_names_for_targets : package_names_for_targets[0]
      end

      # Returns the package versions which need to be modified.  If the resource was called with an array of packages
      # then this will return an array of versions to update (may have 0 or 1 entries).  If the resource was called
      # with a non-array package_name to manage then this will return a string rather than an Array.  The output
      # of this is meant to be fed into subclass interfaces to install/upgrade packages and not all of them are
      # Array-aware.
      #
      # @return [String, Array<String>] package version(s) to actually update/install
      def versions_for_targets
        versions_for_targets = []
        target_version_array.each_with_index do |target_version, i|
          next if target_version.nil?
          versions_for_targets.push(target_version)
        end
        multipackage? ? versions_for_targets : versions_for_targets[0]
      end

      # We need to mutate @new_resource.version() for some reason and this is a helper so that we inject the right
      # class (String or Array) into that attribute based on if we're handling an array of package names or not.
      #
      # @return [String, Array<String>] target_versions coerced into the correct type for back-compat
      def versions_for_new_resource
        if multipackage?
          target_version_array
        else
          target_version_array[0]
        end
      end

      # Return an array indexed the same as *_version_array which contains either the target version to install/upgrade to
      # or else nil if the package is not being modified.
      #
      # @return [Array<String,NilClass>] array of package versions which need to be upgraded (nil = not being upgraded)
      def target_version_array
        @target_version_array ||=
          begin
            target_version_array = []

            each_package do |package_name, new_version, current_version, candidate_version|
              case action
              when :upgrade

                if !candidate_version
                  Chef::Log.debug("#{new_resource} #{package_name} has no candidate_version to upgrade to")
                  target_version_array.push(nil)
                elsif current_version == candidate_version
                  Chef::Log.debug("#{new_resource} #{package_name} the #{candidate_version} is already installed")
                  target_version_array.push(nil)
                else
                  Chef::Log.debug("#{new_resource} #{package_name} is out of date, will upgrade to #{candidate_version}")
                  target_version_array.push(candidate_version)
                end

              when :install

                if new_version
                  if target_version_already_installed?(current_version, new_version)
                    Chef::Log.debug("#{new_resource} #{package_name} #{current_version} satisifies #{new_version} requirement")
                    target_version_array.push(nil)
                  else
                    Chef::Log.debug("#{new_resource} #{package_name} #{current_version} needs updating to #{new_version}")
                    target_version_array.push(new_version)
                  end
                elsif current_version.nil?
                  Chef::Log.debug("#{new_resource} #{package_name} not installed, installing #{candidate_version}")
                  target_version_array.push(candidate_version)
                else
                  Chef::Log.debug("#{new_resource} #{package_name} #{current_version} already installed")
                  target_version_array.push(nil)
                end

              else
                # in specs please test the public interface provider.run_action(:install) instead of provider.action_install
                raise "internal error - target_version_array in package provider does not understand this action"
              end
            end

            target_version_array
          end
      end

      # Check the list of current_version_array and candidate_version_array. For any of the
      # packages if both versions are missing (uninstalled and no candidate) this will be an
      # unsolvable error.
      #
      # @return [Boolean] valid candidates exist for all uninstalled packages
      def candidates_exist_for_all_uninstalled?
        packages_missing_candidates.empty?
      end

      # Returns array of all packages which are missing candidate versions.
      #
      # @return [Array<String>] names of packages missing candidates
      def packages_missing_candidates
        @packages_missing_candidates ||=
          begin
            missing = []
            each_package do |package_name, new_version, current_version, candidate_version|
              missing.push(package_name) if candidate_version.nil? && current_version.nil?
            end
            missing
          end
      end

      # This looks for packages which have a new_version and a current_version, and they are
      # different (a "forced change") and for which there is no candidate.  This is an edge
      # condition that candidates_exist_for_all_uninstalled? does not catch since in this case
      # it is not uninstalled but must be installed anyway and no version exists.
      #
      # @return [Boolean] valid candidates exist for all uninstalled packages
      def candidates_exist_for_all_forced_changes?
        forced_packages_missing_candidates.empty?
      end

      # Returns an array of all forced packages which are missing candidate versions
      #
      # @return [Array] names of packages missing candidates
      def forced_packages_missing_candidates
        @forced_packages_missing_candidates ||=
          begin
            missing = []
            each_package do |package_name, new_version, current_version, candidate_version|
              next if new_version.nil? || current_version.nil?
              if !target_version_already_installed?(current_version, new_version) && candidate_version.nil?
                missing.push(package_name)
              end
            end
            missing
          end
      end

      # Helper to iterate over all the indexed *_array's in sync
      #
      # @yield [package_name, new_version, current_version, candidate_version] Description of block
      def each_package
        package_name_array.each_with_index do |package_name, i|
          candidate_version = candidate_version_array[i]
          current_version = current_version_array[i]
          new_version = new_version_array[i]
          yield package_name, new_version, current_version, candidate_version
        end
      end

      # @return [Boolean] if we're doing a multipackage install or not
      def multipackage?
        new_resource.package_name.is_a?(Array)
      end

      # @return [Array] package_name(s) as an array
      def package_name_array
        [ new_resource.package_name ].flatten
      end

      # @return [Array] candidate_version(s) as an array
      def candidate_version_array
        [ candidate_version ].flatten
      end

      # @return [Array] current_version(s) as an array
      def current_version_array
        [ current_resource.version ].flatten
      end

      # @return [Array] new_version(s) as an array
      def new_version_array
        @new_version_array ||=
            [ new_resource.version ].flatten.map do |v|
              ( v.nil? || v.empty? ) ? nil : v
            end
      end

      # @todo: extract apt/dpkg specific preseeding to a helper class
      def template_available?(path)
        run_context.has_template_in_cookbook?(new_resource.cookbook_name, path)
      end

      # @todo: extract apt/dpkg specific preseeding to a helper class
      def cookbook_file_available?(path)
        run_context.has_cookbook_file_in_cookbook?(new_resource.cookbook_name, path)
      end

    end
  end
end
