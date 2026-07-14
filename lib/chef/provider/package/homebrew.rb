#
# Author:: Joshua Timberman (<joshua@chef.io>)
# Author:: Graeme Mathieson (<mathie@woss.name>)
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require "etc" unless defined?(Etc)
require_relative "../../mixin/homebrew"

class Chef
  class Provider
    class Package
      class Homebrew < Chef::Provider::Package
        allow_nils
        use_multipackage_api

        provides :package, os: "darwin"
        provides :homebrew_package

        include Chef::Mixin::Homebrew

        def load_current_resource
          @current_resource = Chef::Resource::HomebrewPackage.new(new_resource.name)
          current_resource.package_name(new_resource.package_name)
          current_resource.version(get_current_versions)
          logger.trace("#{new_resource} current package version(s): #{current_resource.version}") if current_resource.version

          current_resource
        end

        def define_resource_requirements
          super

          requirements.assert(:all_actions) do |a|
            a.assertion { !new_resource.environment }
            a.failure_message Chef::Exceptions::Package, "The environment property is not supported for package resources on this platform"
          end
        end

        def candidate_version
          package_name_array.map do |package_name|
            available_version(package_name)
          end
        end

        def get_current_versions
          package_name_array.map do |package_name|
            installed_version(package_name)
          end
        end

        def install_package(names, versions)
          brew_cmd_output("install", options, names.compact)
        end

        # upgrades are a bit harder in homebrew than other package formats. If you try to
        # brew upgrade a package that isn't installed it will fail so if a user specifies
        # the action of upgrade we need to figure out which packages need to be installed
        # and which packages can be upgrades. We do this by checking if brew_info has an entry
        # via the installed_version helper.
        def upgrade_package(names, versions)
          upgrade_pkgs = names.select { |x| installed_version(x) }
          install_pkgs = names.reject { |x| installed_version(x) }

          brew_cmd_output("upgrade", options, upgrade_pkgs) unless upgrade_pkgs.empty?
          brew_cmd_output("install", options, install_pkgs) unless install_pkgs.empty?
        end

        def remove_package(names, versions)
          brew_cmd_output("uninstall", options, names.compact)
        end

        # Homebrew doesn't really have a notion of purging, do a "force remove"
        def purge_package(names, versions)
          brew_cmd_output("uninstall", "--force", options, names.compact)
        end

        # We implement a querying method that returns the JSON-as-Hash
        # data for a formula per the Homebrew documentation. Previous
        # implementations of this provider in the homebrew cookbook
        # performed a bit of magic with the load path to get this
        # information, but that is not any more robust than using the
        # command-line interface that returns the same thing.
        #
        # https://docs.brew.sh/Querying-Brew
        #
        # @returns [Hash] a hash of package information where the key is the package name
        def brew_info
          @brew_info ||= begin
            command_array = ["info", "--json=v1"].concat package_name_array
            # convert the array of hashes into a hash where the key is the package name

            cmd_output = brew_cmd_output(command_array, allow_failure: true)

            if cmd_output.empty?
              # we had some kind of failure so we need to iterate through each package to find them
              package_name_array.each_with_object({}) do |package_name, hsh|
                cmd_output = brew_cmd_output("info", "--json=v1", package_name, allow_failure: true)
                if cmd_output.empty?
                  hsh[package_name] = {}
                else
                  json = Chef::JSONCompat.from_json(cmd_output).first
                  hsh[json["name"]] = json
                end
              end
            else
              Hash[Chef::JSONCompat.from_json(cmd_output).collect { |pkg| [pkg["name"], pkg] }]
            end
          end
        end

        #
        # Return the package information given a package name or package alias
        #
        # @param [String] name_or_alias The name of the package or its alias
        #
        # @return [Hash] Package information
        #
        def package_info(package_name)
          # return the package hash if it's in the brew info hash
          return brew_info[package_name] if brew_info[package_name]

          # check each item in the hash to see if we were passed an alias
          brew_info.each_value do |p|
            return p if p["full_name"] == package_name || p["aliases"].include?(package_name)
          end

          {}
        end

        # Some packages (formula) are "keg only" and aren't linked,
        # because multiple versions installed can cause conflicts. We
        # handle this by using the last installed version as the
        # "current" (as in latest). Otherwise, we will use the version
        # that brew thinks is linked as the current version.
        #
        # @param [String] package name
        #
        # @returns [String] package version
        def installed_version(i)
          p_data = package_info(i)

          if p_data["keg_only"]
            if p_data["installed"].empty?
              nil
            else
              p_data["installed"].last["version"]
            end
          else
            p_data["linked_keg"]
          end
        end

        # Packages (formula) available to install should have a
        # "stable" version, per the Homebrew project's acceptable
        # formula documentation, so we will rely on that being the
        # case. Older implementations of this provider in the homebrew
        # cookbook would fall back to +brew_info['version']+, but the
        # schema has changed, and homebrew is a constantly rolling
        # forward project.
        #
        # https://github.com/Homebrew/homebrew/wiki/Acceptable-Formulae#stable-versions
        #
        # @param [String] package name
        #
        # @returns [String] package version
        def available_version(i)
          p_data = package_info(i)

          # nothing is available
          return nil if p_data.empty?

          p_data["versions"]["stable"]
        end

        def brew_cmd_output(*command, **options)
          homebrew_uid = find_homebrew_uid(new_resource.respond_to?(:homebrew_user) && new_resource.homebrew_user)
          homebrew_user = Etc.getpwuid(homebrew_uid)

          logger.trace "Executing '#{homebrew_bin_path} #{command.join(" ")}' as user '#{homebrew_user.name}'"

          # allow the calling method to decide if the cmd should raise or not
          # brew_info uses this when querying out available package info since a bad
          # package name will raise and we want to surface a nil available package so that
          # the package provider can magically handle that
          shell_out_cmd = options[:allow_failure] ? :shell_out : :shell_out!

          output = send(shell_out_cmd, homebrew_bin_path, *command, user: homebrew_uid, environment: { "HOME" => homebrew_user.dir, "RUBYOPT" => nil, "TMPDIR" => nil })
          output.stdout.chomp
        end
      end
    end
  end
end
