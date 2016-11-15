#
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

require "chef/mixin/shell_out"
require "chef/mixin/command"
require "chef/mixin/subclass_directive"
require "chef/log"
require "chef/file_cache"
require "chef/platform"
require "chef/decorator/lazy_array"

class Chef
  class Provider
    class Package < Chef::Provider
      include Chef::Mixin::Command
      include Chef::Mixin::ShellOut
      extend Chef::Mixin::SubclassDirective

      use_inline_resources

      # subclasses declare this if they want all their arguments as arrays of packages and names
      subclass_directive :use_multipackage_api
      # subclasses declare this if they want sources (filenames) pulled from their package names
      subclass_directive :use_package_name_for_source

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

      def check_resource_semantics!
        # FIXME: this is not universally true and subclasses are needing to override this and no-ops it.  It should be turned into
        # another "subclass_directive" and the apt and yum providers should declare that they need this behavior.
        if new_resource.package_name.is_a?(Array) && !new_resource.source.nil?
          raise Chef::Exceptions::InvalidResourceSpecification, "You may not specify both multipackage and source"
        end
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

        # XXX: Does it make sense to pass in a source with :upgrade? Probably
        # not, but as with the above comment, we don't yet enforce such a thing,
        # so we'll just leave things as-is for now.
        requirements.assert(:upgrade, :install) do |a|
          a.assertion { candidates_exist_for_all_uninstalled? || new_resource.source }
          a.failure_message(Chef::Exceptions::Package, "No candidate version available for #{packages_missing_candidates.join(", ")}")
          a.whyrun("Assuming a repository that offers #{packages_missing_candidates.join(", ")} would have been configured")
        end
      end

      action :install do
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

        converge_by(install_description) do
          multipackage_api_adapter(package_names_for_targets, versions_for_targets) do |name, version|
            install_package(name, version)
          end
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

      action :upgrade do
        if !target_version_array.any?
          Chef::Log.debug("#{@new_resource} no versions to upgrade - nothing to do")
          return
        end

        converge_by(upgrade_description) do
          multipackage_api_adapter(package_names_for_targets, versions_for_targets) do |name, version|
            upgrade_package(name, version)
          end
          log_allow_downgrade = allow_downgrade ? "(allow_downgrade)" : ""
          Chef::Log.info("#{@new_resource} upgraded#{log_allow_downgrade} #{package_names_for_targets} to #{versions_for_targets}")
        end
      end

      def upgrade_description
        log_allow_downgrade = allow_downgrade ? "(allow_downgrade)" : ""
        description = []
        target_version_array.each_with_index do |target_version, i|
          next if target_version.nil?
          package_name = package_name_array[i]
          candidate_version = candidate_version_array[i]
          current_version = current_version_array[i] || "uninstalled"
          description << "upgrade#{log_allow_downgrade} package #{package_name} from #{current_version} to #{candidate_version}"
        end
        description
      end

      private :upgrade_description

      action :remove do
        if removing_package?
          description = @new_resource.version ? "version #{@new_resource.version} of " : ""
          converge_by("remove #{description}package #{@current_resource.package_name}") do
            multipackage_api_adapter(@current_resource.package_name, @new_resource.version) do |name, version|
              remove_package(name, version)
            end
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

      action :purge do
        if removing_package?
          description = @new_resource.version ? "version #{@new_resource.version} of" : ""
          converge_by("purge #{description} package #{@current_resource.package_name}") do
            multipackage_api_adapter(@current_resource.package_name, @new_resource.version) do |name, version|
              purge_package(name, version)
            end
            Chef::Log.info("#{@new_resource} purged")
          end
        end
      end

      action :reconfig do
        if @current_resource.version.nil?
          Chef::Log.debug("#{@new_resource} is NOT installed - nothing to do")
          return
        end

        unless @new_resource.response_file
          Chef::Log.debug("#{@new_resource} no response_file provided - nothing to do")
          return
        end

        if preseed_file = get_preseed_file(@new_resource.package_name, @current_resource.version)
          converge_by("reconfigure package #{@new_resource.package_name}") do
            preseed_package(preseed_file)
            multipackage_api_adapter(@new_resource.package_name, @current_resource.version) do |name, version|
              reconfig_package(name, version)

            end
            Chef::Log.info("#{@new_resource} reconfigured")
          end
        else
          Chef::Log.debug("#{@new_resource} preseeding has not changed - nothing to do")
        end
      end

      def action_lock
        if package_locked(@new_resource.name, @new_resource.version) == false
          description = @new_resource.version ? "version #{@new_resource.version} of " : ""
          converge_by("lock #{description}package #{@current_resource.package_name}") do
            multipackage_api_adapter(@current_resource.package_name, @new_resource.version) do |name, version|
              lock_package(name, version)
              Chef::Log.info("#{@new_resource} locked")
            end
          end
        else
          Chef::Log.debug("#{new_resource} is already locked")
        end
      end

      def action_unlock
        if package_locked(@new_resource.name, @new_resource.version) == true
          description = @new_resource.version ? "version #{@new_resource.version} of " : ""
          converge_by("unlock #{description}package #{@current_resource.package_name}") do
            multipackage_api_adapter(@current_resource.package_name, @new_resource.version) do |name, version|
              unlock_package(name, version)
              Chef::Log.info("#{@new_resource} unlocked")
            end
          end
        else
          Chef::Log.debug("#{new_resource} is already unlocked")
        end
      end

      # @todo use composition rather than inheritance

      def multipackage_api_adapter(name, version)
        if use_multipackage_api?
          yield [name].flatten, [version].flatten
        else
          yield name, version
        end
      end

      def install_package(name, version)
        raise Chef::Exceptions::UnsupportedAction, "#{self} does not support :install"
      end

      def upgrade_package(name, version)
        raise Chef::Exceptions::UnsupportedAction, "#{self} does not support :upgrade"
      end

      def remove_package(name, version)
        raise Chef::Exceptions::UnsupportedAction, "#{self} does not support :remove"
      end

      def purge_package(name, version)
        raise Chef::Exceptions::UnsupportedAction, "#{self} does not support :purge"
      end

      def preseed_package(file)
        raise Chef::Exceptions::UnsupportedAction, "#{self} does not support pre-seeding package install/upgrade instructions"
      end

      def reconfig_package(name, version)
        raise( Chef::Exceptions::UnsupportedAction, "#{self} does not support :reconfig" )
      end

      def lock_package(name, version)
        raise( Chef::Exceptions::UnsupportedAction, "#{self} does not support :lock" )
      end

      def unlock_package(name, version)
        raise( Chef::Exceptions::UnsupportedAction, "#{self} does not support :unlock" )
      end

      # used by subclasses.  deprecated.  use #a_to_s instead.
      def expand_options(options)
        options ? " #{options}" : ""
      end

      # Check the current_version against either the candidate_version or the new_version
      #
      # For some reason the windows provider subclasses this (to implement passing Arrays to
      # versions for some reason other than multipackage stuff, which is mildly terrifying).
      #
      # This MUST have 'equality' semantics -- the exact thing matches the exact thing.
      #
      # The current_version should probably be dropped out of the method signature, it should
      # always be the first argument.
      #
      # The name is not just bad, but i find it completely misleading, consider:
      #
      #    target_version_already_installed?(current_version, new_version)
      #    target_version_already_installed?(current_version, candidate_version)
      #
      # which of those is the 'target_version'?  i'd say the new_version and i'm confused when
      # i see it called with the candidate_version.
      #
      # `current_version_equals?(version)` would be a better name
      def target_version_already_installed?(current_version, target_version)
        return false unless current_version && target_version
        current_version == target_version
      end

      # Check the current_version against the new_resource.version, possibly using fuzzy
      # matching criteria.
      #
      # Subclasses MAY override this to provide fuzzy matching on the resource ('>=' and '~>' stuff)
      #
      # This should only ever be offered the same arguments (so they should most likely be
      # removed from the method signature).
      #
      # `new_version_satisfied?()` might be a better name
      def version_requirement_satisfied?(current_version, new_version)
        target_version_already_installed?(current_version, new_version)
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
                if target_version_already_installed?(current_version, new_version)
                  # this is an odd use case
                  Chef::Log.debug("#{new_resource} #{package_name} #{new_version} is already installed -- you are equality pinning with an :upgrade action, this may be deprecated in the future")
                  target_version_array.push(nil)
                elsif target_version_already_installed?(current_version, candidate_version)
                  Chef::Log.debug("#{new_resource} #{package_name} #{candidate_version} is already installed")
                  target_version_array.push(nil)
                elsif candidate_version.nil?
                  Chef::Log.debug("#{new_resource} #{package_name} has no candidate_version to upgrade to")
                  target_version_array.push(nil)
                else
                  Chef::Log.debug("#{new_resource} #{package_name} is out of date, will upgrade to #{candidate_version}")
                  target_version_array.push(candidate_version)
                end

              when :install

                if new_version
                  if version_requirement_satisfied?(current_version, new_version)
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
              missing.push(package_name) if current_version.nil? && candidate_version.nil?
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
              if !version_requirement_satisfied?(current_version, new_version) && candidate_version.nil?
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
        # NOTE: even with use_multipackage_api candidate_version may be a bare nil and need wrapping
        # ( looking at you, dpkg provider... )
        Chef::Decorator::LazyArray.new { [ candidate_version ].flatten }
      end

      # @return [Array] current_version(s) as an array
      def current_version_array
        [ current_resource.version ].flatten
      end

      # @return [Array] new_version(s) as an array
      def new_version_array
        [ new_resource.version ].flatten.map { |v| v.to_s.empty? ? nil : v }
      end

      # TIP: less error prone to simply always call resolved_source_array, even if you
      # don't think that you need to.
      #
      # @return [Array] new_resource.source as an array
      def source_array
        if new_resource.source.nil?
          package_name_array.map { nil }
        else
          [ new_resource.source ].flatten
        end
      end

      # Helper to handle use_package_name_for_source to convert names into local packages to install.
      #
      # @return [Array] Array of sources with package_names converted to sources
      def resolved_source_array
        @resolved_source_array ||=
          begin
            source_array.each_with_index.map do |source, i|
              package_name = package_name_array[i]
              # we require at least one '/' in the package_name to avoid [XXX_]package 'foo' breaking due to a random 'foo' file in cwd
              if use_package_name_for_source? && source.nil? && package_name.match(/#{::File::SEPARATOR}/) && ::File.exist?(package_name)
                Chef::Log.debug("No package source specified, but #{package_name} exists on filesystem, using #{package_name} as source.")
                package_name
              else
                source
              end
            end
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

      def allow_downgrade
        if @new_resource.respond_to?("allow_downgrade")
          @new_resource.allow_downgrade
        else
          false
        end
      end

      def shell_out_with_timeout(*command_args)
        shell_out(*add_timeout_option(command_args))
      end

      def shell_out_with_timeout!(*command_args)
        shell_out!(*add_timeout_option(command_args))
      end

      def add_timeout_option(command_args)
        args = command_args.dup
        if args.last.is_a?(Hash)
          options = args.pop.dup
          options[:timeout] = new_resource.timeout if new_resource.timeout
          options[:timeout] = 900 unless options.has_key?(:timeout)
          args << options
        else
          args << { :timeout => new_resource.timeout ? new_resource.timeout : 900 }
        end
        args
      end
    end
  end
end
