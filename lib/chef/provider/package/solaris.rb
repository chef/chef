#
# Author:: Toomas Pelberg (<toomasp@gmx.net>)
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

class Chef
  class Provider
    class Package
      class Solaris < Chef::Provider::Package

        include Chef::Mixin::GetSourceFromPackage

        provides :solaris_package, target_mode: true

        # def initialize(*args)
        #   super
        #   @current_resource = Chef::Resource::Package.new(new_resource.name)
        # end
        def define_resource_requirements
          super
          requirements.assert(:install) do |a|
            a.assertion { new_resource.source }
            a.failure_message Chef::Exceptions::Package, "Source for package #{new_resource.package_name} required for action install"
          end
          requirements.assert(:all_actions) do |a|
            a.assertion { !new_resource.source || @package_source_found }
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

          if new_resource.source
            @package_source_found = ::TargetIO::File.exist?(new_resource.source)
            if @package_source_found
              logger.trace("#{new_resource} checking pkg status")
              shell_out("pkginfo", "-l", "-d", new_resource.source, new_resource.package_name).stdout.each_line do |line|
                case line
                when /VERSION:\s+(.+)/
                  new_resource.version($1)
                end
              end
            end
          end

          logger.trace("#{new_resource} checking install state")
          status = shell_out("pkginfo", "-l", current_resource.package_name)
          status.stdout.each_line do |line|
            case line
            when /VERSION:\s+(.+)/
              logger.trace("#{new_resource} version #{$1} is already installed")
              current_resource.version($1)
            end
          end

          unless status.exitstatus == 0 || status.exitstatus == 1
            raise Chef::Exceptions::Package, "pkginfo failed - #{status.inspect}!"
          end

          current_resource
        end

        def candidate_version
          return @candidate_version if @candidate_version

          status = shell_out("pkginfo", "-l", "-d", new_resource.source, new_resource.package_name)
          status.stdout.each_line do |line|
            case line
            when /VERSION:\s+(.+)/
              @candidate_version = $1
              new_resource.version($1)
              logger.trace("#{new_resource} setting install candidate version to #{@candidate_version}")
            end
          end
          unless status.exitstatus == 0
            raise Chef::Exceptions::Package, "pkginfo -l -d #{new_resource.source} - #{status.inspect}!"
          end

          @candidate_version
        end

        def install_package(name, version)
          logger.trace("#{new_resource} package install options: #{options}")
          if options.nil?
            command = if ::TargetIO::File.directory?(new_resource.source) # CHEF-4469
                        [ "pkgadd", "-n", "-d", new_resource.source, new_resource.package_name ]
                      else
                        [ "pkgadd", "-n", "-d", new_resource.source, "all" ]
                      end
            shell_out!(command)
            logger.trace("#{new_resource} installed version #{new_resource.version} from: #{new_resource.source}")
          else
            command = if ::TargetIO::File.directory?(new_resource.source) # CHEF-4469
                        [ "pkgadd", "-n", options, "-d", new_resource.source, new_resource.package_name ]
                      else
                        [ "pkgadd", "-n", options, "-d", new_resource.source, "all" ]
                      end
            shell_out!(*command)
            logger.trace("#{new_resource} installed version #{new_resource.version} from: #{new_resource.source}")
          end
        end

        alias upgrade_package install_package

        def remove_package(name, version)
          if options.nil?
            shell_out!( "pkgrm", "-n", name )
            logger.trace("#{new_resource} removed version #{new_resource.version}")
          else
            shell_out!( "pkgrm", "-n", options, name )
            logger.trace("#{new_resource} removed version #{new_resource.version}")
          end
        end

      end
    end
  end
end
