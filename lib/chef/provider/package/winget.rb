#
# Authors:: Adam Jacob (<adam@chef.io>)
#           Ionuț Arțăriși (<iartarisi@suse.cz>)
# Copyright:: Copyright (c) Chef Software Inc.
# Copyright:: 2013-2016, SUSE Linux GmbH
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
require_relative "../../resource/winget_package"

class Chef
  class Provider
    class Package
      class Winget < Chef::Provider::Package
        use_multipackage_api
        allow_nils

        provides :package, platform_family: "windows"
        provides :winget_package

        def load_current_resource
          @current_resource = Chef::Resource::WingetPackage.new(new_resource.name)
          current_resource.package_name(new_resource.package_name)
          current_resource.version(get_current_versions)
          current_resource
        end

        def install_package(name, version)
          puts "here is the version string I was passed by install_package : #{version}"
          actual_version = version
          arguments = build_argument_string
          winget_package("install", name, "--version #{version}", arguments )
        end

        def upgrade_package(name, version)
          # `zypper install` upgrades packages, we rely on the idempotency checks to get action :install behavior
          install_package(name, version)
        end

        private

        def build_argument_string
          build_arguments = ""
          build_arguments << " --source #{new_resource.source_name}" if new_resource.source_name
          build_arguments << " --scope #{new_resource.scope}" if new_resource.scope
          build_arguments << " --override:#{new_resource.options}" if new_resource.options
          build_arguments << " --location #{new_resource.location}" if new_resource.location
          build_arguments << " --force" if new_resource.force
          build_arguments
        end

        def get_current_versions
          puts "The installed version and index are : "
          package_name_array.each_with_index.map { |pkg, i| installed_version(i) }
        end

        def candidate_version
          @candidate_version ||= package_name_array.each_with_index.map { |pkg, i| available_version(i) }
        end

        def is_installed?(package_name)
          ps_results = powershell_exec!("winget list #{package_name}").result
          ps_results.each do |line|
            if line =~ /No installed/
              puts "returning false"
              return false
            elsif line =~ /\d+\.\d+\.\d+\.\d+|\d+\.\d+\.\d+/
              current_version = line.split(' ')
              puts "I think I found this version : #{current_version[-1]}"
              return current_version[-1]
            end
          end
        end

        def get_latest_version(package_name)
          # return a version number
        end

        def resolve_current_version(package_name)
          puts "resolving current version for : #{package_name}"
          latest_version = current_version = nil
          is_installed = false
          # latest version is the one on the Internet
          # current version is the one installed
          # is the damned thing installed locally? If yes, gimme the version from the Internet
          #
          logger.trace("#{new_resource} checking winget")
          status = is_installed?(package_name)
          if status != false
            is_installed = true
            current_version = status
            puts "current version is : #{current_version}"
          end

          latest_version = get_latest_version

          # status = shell_out!("winget", "list", package_name)
          # puts "What is my status : #{status.stdout}"
          # status.stdout.each_line do |line|
          #   if line =~ /^No installed package *: (.+) *$/

          #     # installed_version = $1.strip
          #     # logger.trace("#{new_resource} version #{installed_version}")
          #     # is_installed = true
          #   elsif line =~ /^Name *: (.+) *$/
          # end
          puts "Is #{package_name} installed? : #{is_installed}"
          current_version ||= latest_version if is_installed
          current_version
        end

        # def resolve_current_version(package_name)
        #   latest_version = current_version = nil
        #   is_installed = false
        #   logger.trace("#{new_resource} checking zypper")
        #   status = shell_out!("zypper", "--non-interactive", "info", package_name)
        #   status.stdout.each_line do |line|
        #     case line
        #     when /^Version *: (.+) *$/
        #       latest_version = $1.strip
        #       logger.trace("#{new_resource} version #{latest_version}")
        #     when /^Installed *: Yes.*$/ # http://rubular.com/r/9StcAMjOn6
        #       is_installed = true
        #       logger.trace("#{new_resource} is installed")
        #     when /^Status *: out-of-date \(version (.+) installed\) *$/
        #       current_version = $1.strip
        #       logger.trace("#{new_resource} out of date version #{current_version}")
        #     end
        #   end
        #   current_version ||= latest_version if is_installed
        #   current_version
        # end



        def resolve_available_version(package_name, new_version)
          puts "checking available versions for #{package_name}"
          search_string = new_version.nil? ? package_name : "#{package_name}=#{new_version}"
          so = shell_out!("winget", "search", search_string)
          so.stdout.each_line do |line|
            if line =~ /#{search_string}\s+\w+\.\w+\s+\d+\.\d+\.\d+/
              version = line.split(" ")[2]
              return version
            end
          end
          nil
        end

        def available_version(index)
          @available_version ||= []
          @available_version[index] ||= resolve_available_version(package_name_array[index], safe_version_array[index])
          @available_version[index]
        end

        def installed_version(index)
          puts "here is the installed version #{resolve_current_version(package_name_array[index])} "
          @installed_version ||= []
          @installed_version[index] ||= resolve_current_version(package_name_array[index])
          @installed_version[index]
        end

        def zip(names, versions)
          names.zip(versions).map do |n, v|
            (v.nil? || v.empty?) ? n : "#{n}=#{v}"
          end.compact
        end

        def winget_version
          @winget_version ||=
            `winget --version`.scan(/\d+/).join(".").to_f
        end

        def winget_package(command, name, version, arguments)
          # zipped_names = zip(names, versions)
          # shell_out!("winget", global_options, "--non-interactive", gpg_checks, command, *options, zipped_names)
          shell_out!("winget", command, name, version, arguments)
        end

        # def global_options
        #   new_resource.global_options
        # end

        # def locked_packages
        #   @locked_packages ||=
        #     begin
        #       locked = shell_out!("zypper", "locks")
        #       locked.stdout.each_line.map do |line|
        #         line.split("|").shift(2).last.strip
        #       end
        #     end
        # end

        def safe_version_array
          if new_resource.version.is_a?(Array)
            new_resource.version
          elsif new_resource.version.nil?
            package_name_array.map { nil }
          else
            [ new_resource.version ]
          end
        end

      end
    end
  end
end
