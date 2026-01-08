#
# Author:: Joshua Timberman (<joshua@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
require_relative "../../resource/package"
require_relative "../../mixin/get_source_from_package"
require_relative "yum/rpm_utils"

class Chef
  class Provider
    class Package
      class Rpm < Chef::Provider::Package
        provides :rpm_package, target_mode: true

        include Chef::Mixin::GetSourceFromPackage

        def define_resource_requirements
          super

          requirements.assert(:all_actions) do |a|
            a.assertion { @package_source_exists }
            a.failure_message Chef::Exceptions::Package, "Package #{new_resource.package_name} not found: #{new_resource.source}"
            a.whyrun "Assuming package #{new_resource.package_name} would have been made available."
          end
          requirements.assert(:all_actions) do |a|
            a.assertion { !@rpm_status.nil? && (@rpm_status.exitstatus == 0 || @rpm_status.exitstatus == 1) }
            a.failure_message Chef::Exceptions::Package, "Unable to determine current version due to RPM failure. Detail: #{@rpm_status.inspect}"
            a.whyrun "Assuming current version would have been determined for package #{new_resource.package_name}."
          end
        end

        def load_current_resource
          @package_source_provided = true
          @package_source_exists = true

          @current_resource = Chef::Resource::Package.new(new_resource.name)
          current_resource.package_name(new_resource.package_name)

          if new_resource.source
            unless uri_scheme?(new_resource.source) || ::TargetIO::File.exist?(new_resource.source)
              @package_source_exists = false
              return
            end

            logger.trace("#{new_resource} checking rpm status")
            shell_out!("rpm", "-qp", "--queryformat", "%{NAME} %{VERSION}-%{RELEASE}\n", new_resource.source).stdout.each_line do |line|
              case line
              when /^(\S+)\s(\S+)$/
                current_resource.package_name($1)
                new_resource.version($2)
                @candidate_version = $2
              end
            end
          else
            if Array(new_resource.action).include?(:install)
              @package_source_exists = false
              return
            end
          end

          logger.trace("#{new_resource} checking install state")
          @rpm_status = shell_out("rpm", "-q", "--queryformat", "%{NAME} %{VERSION}-%{RELEASE}\n", current_resource.package_name)
          @rpm_status.stdout.each_line do |line|
            case line
            when /^(\S+)\s(\S+)$/
              logger.trace("#{new_resource} current version is #{$2}")
              current_resource.version($2)
            end
          end

          current_resource
        end

        def install_package(name, version)
          if current_resource.version
            if allow_downgrade
              shell_out!("rpm", options, "-U", "--oldpackage", new_resource.source, env: new_resource.environment)
            else
              shell_out!("rpm", options, "-U", new_resource.source, env: new_resource.environment)
            end
          else
            shell_out!("rpm", options, "-i", new_resource.source, env: new_resource.environment)
          end
        end

        alias upgrade_package install_package

        def remove_package(name, version)
          if version
            shell_out!("rpm", options, "-e", "#{name}-#{version}")
          else
            shell_out!("rpm", options, "-e", name)
          end
        end

        private

        def version_compare(v1, v2)
          Chef::Provider::Package::Yum::RPMVersion.parse(v1) <=> Chef::Provider::Package::Yum::RPMVersion.parse(v2)
        end

        def uri_scheme?(str)
          scheme = URI.split(str).first
          return false unless scheme

          %w{http https ftp file}.include?(scheme.downcase)
        rescue URI::InvalidURIError
          false
        end
      end
    end
  end
end
