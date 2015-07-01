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

require 'chef/provider/package'
require 'chef/mixin/command'
require 'chef/resource/package'

class Chef
  class Provider
    class Package
      class Apt < Chef::Provider::Package

        provides :package, platform_family: "debian"
        provides :apt_package, os: "linux"

        # return [Hash] mapping of package name to Boolean value
        attr_accessor :is_virtual_package

        def initialize(new_resource, run_context)
          super
          @is_virtual_package = {}
        end

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)
          check_all_packages_state(@new_resource.package_name)
          @current_resource
        end

        def define_resource_requirements
          super

          requirements.assert(:all_actions) do |a|
            a.assertion { !@new_resource.source }
            a.failure_message(Chef::Exceptions::Package, 'apt package provider cannot handle source attribute. Use dpkg provider instead')
          end
        end

        def default_release_options
          # Use apt::Default-Release option only if provider supports it
          "-o APT::Default-Release=#{@new_resource.default_release}" if @new_resource.respond_to?(:default_release) && @new_resource.default_release
        end

        def check_package_state(pkg)
          is_virtual_package = false
          installed          = false
          installed_version  = nil
          candidate_version  = nil

          shell_out_with_timeout!("apt-cache#{expand_options(default_release_options)} policy #{pkg}").stdout.each_line do |line|
            case line
            when /^\s{2}Installed: (.+)$/
              installed_version = $1
              if installed_version == '(none)'
                Chef::Log.debug("#{@new_resource} current version is nil")
                installed_version = nil
              else
                Chef::Log.debug("#{@new_resource} current version is #{installed_version}")
                installed = true
              end
            when /^\s{2}Candidate: (.+)$/
              candidate_version = $1
              if candidate_version == '(none)'
                # This may not be an appropriate assumption, but it shouldn't break anything that already worked -- btm
                is_virtual_package = true
                showpkg = shell_out_with_timeout!("apt-cache showpkg #{pkg}").stdout
                providers = Hash.new
                showpkg.rpartition(/Reverse Provides: ?#{$/}/)[2].each_line do |line|
                  provider, version = line.split
                  providers[provider] = version
                end
                # Check if the package providing this virtual package is installed
                num_providers = providers.length
                raise Chef::Exceptions::Package, "#{@new_resource.package_name} has no candidate in the apt-cache" if num_providers == 0
                # apt will only install a virtual package if there is a single providing package
                raise Chef::Exceptions::Package, "#{@new_resource.package_name} is a virtual package provided by #{num_providers} packages, you must explicitly select one to install" if num_providers > 1
                # Check if the package providing this virtual package is installed
                Chef::Log.info("#{@new_resource} is a virtual package, actually acting on package[#{providers.keys.first}]")
                ret = check_package_state(providers.keys.first)
                installed = ret[:installed]
                installed_version = ret[:installed_version]
              else
                Chef::Log.debug("#{@new_resource} candidate version is #{$1}")
              end
            end
          end

          return {
            installed_version:   installed_version,
            installed:           installed,
            candidate_version:   candidate_version,
            is_virtual_package:  is_virtual_package,
          }
        end

        def check_all_packages_state(package)
          installed_version = {}
          candidate_version = {}
          installed = {}

          [package].flatten.each do |pkg|
            ret = check_package_state(pkg)
            is_virtual_package[pkg] = ret[:is_virtual_package]
            installed[pkg]          = ret[:installed]
            installed_version[pkg]  = ret[:installed_version]
            candidate_version[pkg]  = ret[:candidate_version]
          end

          if package.is_a?(Array)
            @candidate_version = []
            final_installed_version = []
            [package].flatten.each do |pkg|
              @candidate_version << candidate_version[pkg]
              final_installed_version << installed_version[pkg]
            end
            @current_resource.version(final_installed_version)
          else
            @candidate_version = candidate_version[package]
            @current_resource.version(installed_version[package])
          end
        end

        def install_package(name, version)
          name_array = [ name ].flatten
          version_array = [ version ].flatten
          package_name = name_array.zip(version_array).map do |n, v|
            is_virtual_package[n] ? n : "#{n}=#{v}"
          end.join(' ')
          run_noninteractive("apt-get -q -y#{expand_options(default_release_options)}#{expand_options(@new_resource.options)} install #{package_name}")
        end

        def upgrade_package(name, version)
          install_package(name, version)
        end

        def remove_package(name, version)
          package_name = [ name ].flatten.join(' ')
          run_noninteractive("apt-get -q -y#{expand_options(@new_resource.options)} remove #{package_name}")
        end

        def purge_package(name, version)
          package_name = [ name ].flatten.join(' ')
          run_noninteractive("apt-get -q -y#{expand_options(@new_resource.options)} purge #{package_name}")
        end

        def preseed_package(preseed_file)
          Chef::Log.info("#{@new_resource} pre-seeding package installation instructions")
          run_noninteractive("debconf-set-selections #{preseed_file}")
        end

        def reconfig_package(name, version)
          package_name = [ name ].flatten.join(' ')
          Chef::Log.info("#{@new_resource} reconfiguring")
          run_noninteractive("dpkg-reconfigure #{package_name}")
        end

        private

        # Runs command via shell_out with magic environment to disable
        # interactive prompts. Command is run with default localization rather
        # than forcing locale to "C", so command output may not be stable.
        def run_noninteractive(command)
          shell_out_with_timeout!(command, :env => { "DEBIAN_FRONTEND" => "noninteractive", "LC_ALL" => nil })
        end

      end
    end
  end
end
