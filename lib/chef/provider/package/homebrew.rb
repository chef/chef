#
# Author:: Joshua Timberman (<joshua@getchef.com>)
# Author:: Graeme Mathieson (<mathie@woss.name>)
#
# Copyright 2011-2013, Opscode, Inc.
# Copyright 2014, Chef Software, Inc <legal@getchef.com>
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

require 'etc'
require 'chef/mixin/homebrew_user'

class Chef
  class Provider
    class Package
      class Homebrew < Chef::Provider::Package

        provides :homebrew_package

        include Chef::Mixin::HomebrewUser

        def load_current_resource
          self.current_resource = Chef::Resource::Package.new(new_resource.name)
          current_resource.package_name(new_resource.package_name)
          current_resource.version(current_installed_version)
          Chef::Log.debug("#{new_resource} current version is #{current_resource.version}") if current_resource.version

          @candidate_version = candidate_version

          Chef::Log.debug("#{new_resource} candidate version is #{@candidate_version}") if @candidate_version

          current_resource
        end

        def install_package(name, version)
          unless current_resource.version == version
            brew('install', new_resource.options, name)
          end
        end

        def upgrade_package(name, version)
          current_version = current_resource.version

          if current_version.nil? or current_version.empty?
            install_package(name, version)
          elsif current_version != version
            brew('upgrade', new_resource.options, name)
          end
        end

        def remove_package(name, version)
          if current_resource.version
            brew('uninstall', new_resource.options, name)
          end
        end

        # Homebrew doesn't really have a notion of purging, do a "force remove"
        def purge_package(name, version)
          new_resource.options((new_resource.options || '') << ' --force').strip
          remove_package(name, version)
        end

        def brew(*args)
          get_response_from_command("brew #{args.join(' ')}")
        end

        # We implement a querying method that returns the JSON-as-Hash
        # data for a formula per the Homebrew documentation. Previous
        # implementations of this provider in the homebrew cookbook
        # performed a bit of magic with the load path to get this
        # information, but that is not any more robust than using the
        # command-line interface that returns the same thing.
        #
        # https://github.com/Homebrew/homebrew/wiki/Querying-Brew
        def brew_info
          @brew_info ||= Chef::JSONCompat.from_json(brew('info', '--json=v1', new_resource.package_name)).first
        end

        # Some packages (formula) are "keg only" and aren't linked,
        # because multiple versions installed can cause conflicts. We
        # handle this by using the last installed version as the
        # "current" (as in latest). Otherwise, we will use the version
        # that brew thinks is linked as the current version.
        #
        def current_installed_version
          if brew_info['keg_only']
            if brew_info['installed'].empty?
              nil
            else
              brew_info['installed'].last['version']
            end
          else
            brew_info['linked_keg']
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
        def candidate_version
          brew_info['versions']['stable']
        end

        private

        def get_response_from_command(command)
          homebrew_uid = find_homebrew_uid(new_resource.respond_to?(:homebrew_user) && new_resource.homebrew_user)
          homebrew_user = Etc.getpwuid(homebrew_uid)

          Chef::Log.debug "Executing '#{command}' as user '#{homebrew_user.name}'"
          output = shell_out!(command, :timeout => 1800, :user => homebrew_uid, :environment => { 'HOME' => homebrew_user.dir, 'RUBYOPT' => nil })
          output.stdout.chomp
        end

      end
    end
  end
end
