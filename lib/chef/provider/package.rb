#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../mixin/subclass_directive"
require_relative "../log"
require_relative "../file_cache"
require_relative "../platform"
require_relative "../decorator/lazy_array"
require "shellwords" unless defined?(Shellwords)

class Chef
  class Provider
    class Package < Chef::Provider
      extend Chef::Mixin::SubclassDirective

      # subclasses declare this if they want all their arguments as arrays of packages and names.
      # any new packages using this should also use allow_nils below.
      #
      subclass_directive :use_multipackage_api

      # subclasses declare this if they want sources (filenames) pulled from their package names.
      # this is for package providers that take a path into the filesystem (rpm, dpkg).
      #
      subclass_directive :use_package_name_for_source

      # keeps package_names_for_targets and versions_for_targets indexed the same as package_name at
      # the cost of having the subclass needing to deal with nils.  all providers are encouraged to
      # migrate to using this as it simplifies dealing with package aliases in subclasses.
      #
      subclass_directive :allow_nils

      # subclasses that implement complex pattern matching using constraints, particularly the yum and
      # dnf classes, should filter the installed version against the desired version constraint and
      # return nil if it does not match.  this means that 'nil' does not mean that no version of the
      # package is installed, but that the installed version does not satisfy the desired constraints.
      # (the package plus the constraints are not installed)
      #
      # [ this may arguably be useful for all package providers and it greatly simplifies the logic
      #   in the superclass that gets executed, so maybe this should always be used now? ]
      #
      # note that when using this feature that the current_resource.version must be loaded with the
      # correct currently installed version, without doing the filtering -- for reporting and for
      # correctly displaying version upgrades.  that means there are 3 different arrays which must be
      # loaded by the subclass:  candidate_version, magic_version and current_resource.version.
      #
      # NOTE: magic_version is a terrible name, but I couldn't think of anything better, at least this
      #       way it stands out clearly.
      #
      subclass_directive :use_magic_version

      #
      # Hook that subclasses use to populate the candidate_version(s)
      #
      # @return [Array, String] candidate_version(s) may be a string or array
      attr_accessor :candidate_version

      def initialize(new_resource, run_context)
        super
        @candidate_version = nil
      end

      def options
        new_resource.options
      end

      def check_resource_semantics!
        # FIXME: this is not universally true and subclasses are needing to override this and no-ops it.  It should be turned into
        # another "subclass_directive" and the apt and yum providers should declare that they need this behavior.
        if new_resource.package_name.is_a?(Array) && !new_resource.source.nil?
          raise Chef::Exceptions::InvalidResourceSpecification, "You may not specify both multipackage and source"
        end
      end

      def load_current_resource; end

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
          logger.debug("#{new_resource} is already installed - nothing to do")
          return
        end

        prepare_for_installation

        converge_by(install_description) do
          multipackage_api_adapter(package_names_for_targets, versions_for_targets) do |name, version|
            install_package(name, version)
          end
          logger.info("#{new_resource} installed #{package_names_for_targets} at #{versions_for_targets}")
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
        unless target_version_array.any?
          logger.debug("#{new_resource} no versions to upgrade - nothing to do")
          return
        end

        converge_by(upgrade_description) do
          multipackage_api_adapter(package_names_for_targets, versions_for_targets) do |name, version|
            upgrade_package(name, version)
          end
          log_allow_downgrade = allow_downgrade ? "(allow_downgrade)" : ""
          logger.info("#{new_resource} upgraded#{log_allow_downgrade} #{package_names_for_targets} to #{versions_for_targets}")
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
          description = new_resource.version ? "version #{new_resource.version} of " : ""
          converge_by("remove #{description}package #{current_resource.package_name}") do
            multipackage_api_adapter(current_resource.package_name, new_resource.version) do |name, version|
              remove_package(name, version)
            end
            logger.info("#{new_resource} removed")
          end
        else
          logger.debug("#{new_resource} package does not exist - nothing to do")
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
          description = new_resource.version ? "version #{new_resource.version} of" : ""
          converge_by("purge #{description} package #{current_resource.package_name}") do
            multipackage_api_adapter(current_resource.package_name, new_resource.version) do |name, version|
              purge_package(name, version)
            end
            logger.info("#{new_resource} purged")
          end
        end
      end

      action :lock do
        packages_locked = if respond_to?(:packages_all_locked?, true)
                            packages_all_locked?(Array(new_resource.package_name), Array(new_resource.version))
                          else
                            package_locked(new_resource.package_name, new_resource.version)
                          end
        unless packages_locked
          description = new_resource.version ? "version #{new_resource.version} of " : ""
          converge_by("lock #{description}package #{current_resource.package_name}") do
            multipackage_api_adapter(current_resource.package_name, new_resource.version) do |name, version|
              lock_package(name, version)
              logger.info("#{new_resource} locked")
            end
          end
        else
          logger.debug("#{new_resource} is already locked")
        end
      end

      action :unlock do
        packages_unlocked = if respond_to?(:packages_all_unlocked?, true)
                              packages_all_unlocked?(Array(new_resource.package_name), Array(new_resource.version))
                            else
                              !package_locked(new_resource.package_name, new_resource.version)
                            end
        unless packages_unlocked
          description = new_resource.version ? "version #{new_resource.version} of " : ""
          converge_by("unlock #{description}package #{current_resource.package_name}") do
            multipackage_api_adapter(current_resource.package_name, new_resource.version) do |name, version|
              unlock_package(name, version)
              logger.info("#{new_resource} unlocked")
            end
          end
        else
          logger.debug("#{new_resource} is already unlocked")
        end
      end

      # for multipackage just implement packages_all_[un]locked? properly and omit implementing this API
      def package_locked(name, version)
        raise Chef::Exceptions::UnsupportedAction, "#{self} has no way to detect if package is locked"
      end

      # Subclasses will override this to a method and provide a preseed file path
      def prepare_for_installation; end

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

      def reconfig_package(name)
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
        # its deprecated but still work to do to deprecate it fully
        # Chef.deprecated(:package_misc, "expand_options is deprecated, use shell_out instead")
        if options
          " #{options.is_a?(Array) ? Shellwords.join(options) : options}"
        else
          ""
        end
      end

      # Check the current_version against either the candidate_version or the new_version
      #
      # For some reason the windows provider subclasses this (to implement passing Arrays to
      # versions for some reason other than multipackage stuff, which is mildly terrifying).
      #
      # This MUST have 'equality' semantics -- the exact thing matches the exact thing.
      #
      # The name is not just bad, but i find it completely misleading, consider:
      #
      #    target_version_already_installed?(current_version, new_version)
      #    target_version_already_installed?(current_version, candidate_version)
      #
      # Which of those is the 'target_version'?  I'd say the new_version and I'm confused when
      # i see it called with the candidate_version.
      #
      # `version_equals?(v1, v2)` would be a better name.
      #
      # Note that most likely we need a spaceship operator on versions that subclasses can implement
      # and we should have `version_compare(v1, v2)` that returns `v1 <=> v2`.

      # This method performs a strict equality check between two strings representing version numbers
      #
      # This function will eventually be deprecated in favour of the below version_equals function.

      def target_version_already_installed?(current_version, target_version)
        version_equals?(current_version, target_version)
      end

      # Note that most likely we need a spaceship operator on versions that subclasses can implement
      # and we should have `version_compare(v1, v2)` that returns `v1 <=> v2`.

      # This method performs a strict equality check between two strings representing version numbers
      #
      def version_equals?(v1, v2)
        return false unless v1 && v2

        v1 == v2
      end

      # This function compares two version numbers and returns 'spaceship operator' style results, ie:
      # if v1 < v2 then return -1
      # if v1 = v2 then return  0
      # if v1 > v2 then return  1
      # if v1 and v2 are not comparable then return nil
      #
      # By default, this function will use Gem::Version comparison. Subclasses can reimplement this method
      # for package-management system specific versions.
      #
      # (In other words, pull requests to introduce domain specific mangling of versions into this method
      # will be closed -- that logic must go into the subclass -- we understand that this is far from perfect
      # but it is a better default than outright buggy things like v1.to_f <=> v2.to_f)
      #
      def version_compare(v1, v2)
        gem_v1 = Gem::Version.new(v1.gsub(/\A\s*(#{Gem::Version::VERSION_PATTERN}).*/, '\1'))
        gem_v2 = Gem::Version.new(v2.gsub(/\A\s*(#{Gem::Version::VERSION_PATTERN}).*/, '\1'))

        gem_v1 <=> gem_v2
      end

      # Check the current_version against the new_resource.version, possibly using fuzzy
      # matching criteria.
      #
      # Subclasses MAY override this to provide fuzzy matching on the resource ('>=' and '~>' stuff)
      #
      # `version_satisfied_by?(version, constraint)` might be a better name to make this generic.
      #
      def version_requirement_satisfied?(current_version, new_version)
        target_version_already_installed?(current_version, new_version)
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
          if !target_version.nil?
            package_name = package_name_array[i]
            package_names_for_targets.push(package_name)
          else
            package_names_for_targets.push(nil) if allow_nils?
          end
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
          if !target_version.nil?
            versions_for_targets.push(target_version)
          else
            versions_for_targets.push(nil) if allow_nils?
          end
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
                if current_version.nil?
                  # with use_magic_version there may be a package installed, but it fails the user's
                  # requested new_resource.version constraints
                  logger.trace("#{new_resource} has no existing installed version. Installing install #{candidate_version}")
                  target_version_array.push(candidate_version)
                elsif !use_magic_version? && version_equals?(current_version, new_version)
                  # this is a short-circuit (mostly for the rubygems provider) to avoid needing to expensively query the candidate_version which must come later
                  logger.trace("#{new_resource} #{package_name} #{new_version} is already installed")
                  target_version_array.push(nil)
                elsif candidate_version.nil?
                  logger.trace("#{new_resource} #{package_name} has no candidate_version to upgrade to")
                  target_version_array.push(nil)
                elsif version_equals?(current_version, candidate_version)
                  logger.trace("#{new_resource} #{package_name} #{candidate_version} is already installed")
                  target_version_array.push(nil)
                elsif !allow_downgrade && version_compare(current_version, candidate_version) == 1
                  logger.trace("#{new_resource} #{package_name} has installed version #{current_version}, which is newer than available version #{candidate_version}. Skipping...)")
                  target_version_array.push(nil)
                else
                  logger.trace("#{new_resource} #{package_name} is out of date, will upgrade to #{candidate_version}")
                  target_version_array.push(candidate_version)
                end

              when :install
                if new_version && !use_magic_version?
                  if version_requirement_satisfied?(current_version, new_version)
                    logger.trace("#{new_resource} #{package_name} #{current_version} satisfies #{new_version} requirement")
                    target_version_array.push(nil)
                  elsif current_version && !allow_downgrade && version_compare(current_version, new_version) == 1
                    logger.warn("#{new_resource} #{package_name} has installed version #{current_version}, which is newer than available version #{new_version}. Skipping...)")
                    target_version_array.push(nil)
                  else
                    logger.trace("#{new_resource} #{package_name} #{current_version} needs updating to #{new_version}")
                    target_version_array.push(new_version)
                  end
                elsif current_version.nil?
                  # with use_magic_version there may be a package installed, but it fails the user's
                  # requested new_resource.version constraints
                  logger.trace("#{new_resource} #{package_name} not installed, installing #{candidate_version}")
                  target_version_array.push(candidate_version)
                else
                  logger.trace("#{new_resource} #{package_name} #{current_version} already installed")
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

              if use_magic_version?
                if !magic_version && candidate_version.nil?
                  missing.push(package_name)
                end
              else
                if !version_requirement_satisfied?(current_version, new_version) && candidate_version.nil?
                  missing.push(package_name)
                end
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
          current_version = use_magic_version? ? magic_version[i] : current_version_array[i]
          new_version = new_version_array[i]
          yield package_name, new_version, current_version, candidate_version
        end
      end

      # @return [Boolean] if we're doing a multipackage install or not
      def multipackage?
        @multipackage_bool ||= new_resource.package_name.is_a?(Array)
      end

      # @return [Array] package_name(s) as an array
      def package_name_array
        @package_name_array ||= [ new_resource.package_name ].flatten
      end

      # @return [Array] candidate_version(s) as an array
      def candidate_version_array
        # NOTE: even with use_multipackage_api candidate_version may be a bare nil and need wrapping
        # ( looking at you, dpkg provider... )
        Chef::Decorator::LazyArray.new { [ candidate_version ].flatten }
      end

      # @return [Array] current_version(s) as an array
      def current_version_array
        @current_version_array ||= [ current_resource.version ].flatten
      end

      # @return [Array] new_version(s) as an array
      def new_version_array
        @new_version_array ||= [ new_resource.version ].flatten.map { |v| v.to_s.empty? ? nil : v }
      end

      # TIP: less error prone to simply always call resolved_source_array, even if you
      # don't think that you need to.
      #
      # @return [Array] new_resource.source as an array
      def source_array
        @source_array ||=
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
          source_array.each_with_index.map do |source, i|
            package_name = package_name_array[i]
            # we require at least one '/' in the package_name to avoid [XXX_]package 'foo' breaking due to a random 'foo' file in cwd
            if use_package_name_for_source? && source.nil? && package_name.match(/#{::File::SEPARATOR}/) && ::File.exist?(package_name)
              logger.trace("No package source specified, but #{package_name} exists on filesystem, using #{package_name} as source.")
              package_name
            else
              source
            end
          end
      end

      def allow_downgrade
        if new_resource.respond_to?("allow_downgrade")
          new_resource.allow_downgrade
        else
          true
        end
      end
    end
  end
end
