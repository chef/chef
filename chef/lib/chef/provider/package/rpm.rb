#
# Author:: Joshua Timberman (<joshua@opscode.com>)
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
require 'chef/mixin/get_source_from_package'

class Chef
  class Provider
    class Package
      class Rpm < Chef::Provider::Package
        include Chef::Mixin::Command
        include Chef::Mixin::GetSourceFromPackage

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)

          assert_install_action_requires_source!

          rpm_name, rpm_version = package_name_and_version

          @new_resource.version          rpm_version
          @current_resource.package_name rpm_name
          @current_resource.version      installed_version

          @current_resource
        end

        def install_package(name, version)
          unless @current_resource.version
            shell_out_with_systems_locale! "rpm #{@new_resource.options} -i #{@new_resource.source}"
          else
            shell_out_with_systems_locale! "rpm #{@new_resource.options} -U #{@new_resource.source}"
          end
        end

        alias_method :upgrade_package, :install_package

        def remove_package(name, version)
          if version
            shell_out_with_systems_locale! "rpm #{@new_resource.options} -e #{name}-#{version}"
          else
            shell_out_with_systems_locale! "rpm #{@new_resource.options} -e #{name}"
          end
        end

        def assert_install_action_requires_source!
          return if @new_resource.source || !Array(@new_resource.action).include?(:install)
          raise Chef::Exceptions::Package, "Source for package #{@new_resource.name} required for action install"
        end

        def assert_rpm_exists!
          return if ::File.exists?(@new_resource.source)
          raise Chef::Exceptions::Package, "Package #{@new_resource.name} not found: #{@new_resource.source}"
        end

        def package_name_and_version
          return unless @new_resource.source
          assert_rpm_exists!


          Chef::Log.debug("#{@new_resource} checking rpm status")
          status = popen4("rpm -qp --queryformat '%{NAME} %{VERSION}-%{RELEASE}\n' #{@new_resource.source}") do |pid, stdin, stdout, stderr|
            stdout.each do |line|
              case line
              when /([\w\d_.-]+)\s([\w\d_.-]+)/
                return [$1, $2] # package_name, version
              end
            end
          end

          return [nil, nil]
        end

        def installed_version
          Chef::Log.debug("#{@new_resource} checking install state")
          status = popen4("rpm -q --queryformat '%{NAME} %{VERSION}-%{RELEASE}\n' #{@current_resource.package_name}") do |pid, stdin, stdout, stderr|
            stdout.each do |line|
              case line
              when /([\w\d_.-]+)\s([\w\d_.-]+)/
                Chef::Log.debug("#{@new_resource} current version is #{$2}")
                return $2 # installed version
              end
            end
          end

          unless status.exitstatus == 0 || status.exitstatus == 1
            raise Chef::Exceptions::Package, "rpm failed - #{status.inspect}!"
          end
        end

      end
    end
  end
end

