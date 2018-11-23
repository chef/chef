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
          logger.trace("#{new_resource} current version is #{current_resource.version}") if current_resource.version

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
          packages = names.select { |x| x unless x.nil? }
          brew("install", options, packages)
        end

        def upgrade_package(name, version)
          current_version = current_resource.version

          if current_version.nil? || current_version.empty?
            install_package(name, version)
          elsif current_version != version
            brew("upgrade", options, name)
          end
        end

        def remove_package(names, versions)
          packages = names.select { |x| x unless x.nil? }
          brew("uninstall", options, packages)
        end

        # Homebrew doesn't really have a notion of purging, do a "force remove"
        def purge_package(names, versions)
          packages = names.select { |x| x unless x.nil? }
          brew("uninstall", "--force", options, packages)
        end

        def brew(*args)
          get_response_from_command("brew", *args)
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
            command_array = ["info", "--json=v1"].concat new_resource.package_name
            # convert the array of hashes into a hash where the key is the package name
            Hash[Chef::JSONCompat.from_json(brew(command_array)).collect { |pkg| [pkg["name"], pkg] }]
          end
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
          if brew_info[i]["keg_only"]
            if brew_info[i]["installed"].empty?
              nil
            else
              brew_info[i]["installed"].last["version"]
            end
          else
            brew_info[i]["linked_keg"]
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
          brew_info[i]["versions"]["stable"]
        end

        private

        def get_response_from_command(*command)
          homebrew_uid = find_homebrew_uid(new_resource.respond_to?(:homebrew_user) && new_resource.homebrew_user)
          homebrew_user = Etc.getpwuid(homebrew_uid)

          logger.trace "Executing '#{command.join(" ")}' as user '#{homebrew_user.name}'"
          # FIXME: this 1800 second default timeout should be deprecated
          output = shell_out!(*command, timeout: 1800, user: homebrew_uid, environment: { "HOME" => homebrew_user.dir, "RUBYOPT" => nil, "TMPDIR" => nil })
          output.stdout.chomp
        end

      end
    end
  end
end
