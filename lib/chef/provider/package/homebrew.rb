#
# Author:: Joshua Timberman (<joshua@chef.io>)
# Author:: Graeme Mathieson (<mathie@woss.name>)
#
# Copyright:: Copyright (c) Chef Software Inc.
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
require_relative "../../mixin/homebrew_user"

class Chef
  class Provider
    class Package
      class Homebrew < Chef::Provider::Package
        allow_nils
        use_multipackage_api

        provides :package, os: "darwin", override: true
        provides :homebrew_package

        include Chef::Mixin::HomebrewUser

        def load_current_resource
          @current_resource = Chef::Resource::HomebrewPackage.new(new_resource.name)
          current_resource.package_name(new_resource.package_name)
          current_resource.version(get_current_versions)
          logger.trace("#{new_resource} current package version(s): #{current_resource.version}") if current_resource.version

          current_resource
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

        def upgrade_package(name, version)
          current_version = current_resource.version

          if current_version.nil? || current_version.empty?
            install_package(name, version)
          elsif current_version != version
            brew_cmd_output("upgrade", options, name)
          end
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
            command_array = ["info", "--json=v1"].concat Array(new_resource.package_name)
            # convert the array of hashes into a hash where the key is the package name
            Hash[Chef::JSONCompat.from_json(brew_cmd_output(command_array)).collect { |pkg| [pkg["name"], pkg] }]
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
            return p if p["aliases"].include?(package_name)
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

          p_data["versions"]["stable"]
        end

        def brew_cmd_output(*command)
          homebrew_uid = find_homebrew_uid(new_resource.respond_to?(:homebrew_user) && new_resource.homebrew_user)
          homebrew_user = Etc.getpwuid(homebrew_uid)

          logger.trace "Executing 'brew #{command.join(" ")}' as user '#{homebrew_user.name}'"
          # FIXME: this 1800 second default timeout should be deprecated
          output = shell_out!('brew', *command, timeout: 1800, user: homebrew_uid, environment: { "HOME" => homebrew_user.dir, "RUBYOPT" => nil, "TMPDIR" => nil })
          output.stdout.chomp
        end

      end
    end
  end
end
