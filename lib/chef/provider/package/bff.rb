#
# Author:: Deepali Jagtap
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
require_relative "../package"
require_relative "../../resource/package"
require_relative "../../mixin/get_source_from_package"

class Chef
  class Provider
    class Package
      class Bff < Chef::Provider::Package

        provides :package, os: "aix", target_mode: true
        provides :bff_package, target_mode: true

        include Chef::Mixin::GetSourceFromPackage

        def define_resource_requirements
          super
          requirements.assert(:install) do |a|
            a.assertion { new_resource.source }
            a.failure_message Chef::Exceptions::Package, "Source for package #{new_resource.package_name} required for action install"
          end
          requirements.assert(:all_actions) do |a|
            a.assertion { !new_resource.source || package_source_found? }
            a.failure_message Chef::Exceptions::Package, "Package #{new_resource.package_name} not found: #{new_resource.source}"
            a.whyrun "would assume #{new_resource.source} would be have previously been made available"
          end

          requirements.assert(:all_actions) do |a|
            a.assertion { !new_resource.environment }
            a.failure_message Chef::Exceptions::Package, "The environment property is not supported for package resources on this platform"
          end
        end

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(new_resource.name)
          current_resource.package_name(new_resource.package_name)

          if package_source_found?
            logger.trace("#{new_resource} checking pkg status")
            ret = shell_out("installp", "-L", "-d", new_resource.source)
            ret.stdout.each_line do |line|
              case line
              when /:#{new_resource.package_name}:/
                fields = line.split(":")
                new_resource.version(fields[2])
              when /^#{new_resource.package_name}:/
                logger.warn("You are installing a bff package by product name. For idempotent installs, please install individual filesets")
                fields = line.split(":")
                new_resource.version(fields[2])
              end
            end
            raise Chef::Exceptions::Package, "package source #{new_resource.source} does not provide package #{new_resource.package_name}" unless new_resource.version
          end

          logger.trace("#{new_resource} checking install state")
          ret = shell_out("lslpp", "-lcq", current_resource.package_name)
          ret.stdout.each_line do |line|
            case line
            when /#{current_resource.package_name}/
              fields = line.split(":")
              logger.trace("#{new_resource} version #{fields[2]} is already installed")
              current_resource.version(fields[2])
            end
          end

          unless ret.exitstatus == 0 || ret.exitstatus == 1
            raise Chef::Exceptions::Package, "lslpp failed - #{ret.format_for_exception}!"
          end

          current_resource
        end

        def candidate_version
          return @candidate_version if @candidate_version

          if package_source_found?
            ret = shell_out("installp", "-L", "-d", new_resource.source)
            ret.stdout.each_line do |line|
              case line
              when /\w:#{Regexp.escape(new_resource.package_name)}:(.*)/
                fields = line.split(":")
                @candidate_version = fields[2]
                new_resource.version(fields[2])
                logger.trace("#{new_resource} setting install candidate version to #{@candidate_version}")
              end
            end
            unless ret.exitstatus == 0
              raise Chef::Exceptions::Package, "installp -L -d #{new_resource.source} - #{ret.format_for_exception}!"
            end
          end
          @candidate_version
        end

        #
        # The install/update action needs to be tested with various kinds of packages
        # on AIX viz. packages with or without licensing file dependencies, packages
        # with dependencies on other packages which will help to test additional
        # options of installp.
        # So far, the code has been tested only with standalone packages.
        #
        def install_package(name, version)
          logger.trace("#{new_resource} package install options: #{options}")
          if options.nil?
            shell_out!("installp", "-aYF", "-d", new_resource.source, new_resource.package_name)
            logger.trace("#{new_resource} installed version #{new_resource.version} from: #{new_resource.source}")
          else
            shell_out!("installp", "-aYF", options, "-d", new_resource.source, new_resource.package_name)
            logger.trace("#{new_resource} installed version #{new_resource.version} from: #{new_resource.source}")
          end
        end

        alias upgrade_package install_package

        def remove_package(name, version)
          if options.nil?
            shell_out!("installp", "-u", name)
            logger.trace("#{new_resource} removed version #{new_resource.version}")
          else
            shell_out!("installp", "-u", options, name)
            logger.trace("#{new_resource} removed version #{new_resource.version}")
          end
        end

        def package_source_found?
          @package_source_found ||= new_resource.source && ::TargetIO::File.exist?(new_resource.source)
        end

      end
    end
  end
end
