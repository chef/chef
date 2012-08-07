#
# Author:: Toomas Pelberg (<toomasp@gmx.net>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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
      class Solaris < Chef::Provider::Package

        include Chef::Mixin::GetSourceFromPackage

        # def initialize(*args)
        #   super
        #   @current_resource = Chef::Resource::Package.new(@new_resource.name)
        # end
        def define_resource_requirements
          super
          requirements.assert(:install) do |a| 
            a.assertion { @new_resource.source }
            a.failure_message Chef::Exceptions::Package, "Source for package #{@new_resource.name} required for action install"
          end
          requirements.assert(:all_actions) do |a| 
            a.assertion { !@new_resource.source || @package_source_found } 
            a.failure_message Chef::Exceptions::Package, "Package #{@new_resource.name} not found: #{@new_resource.source}"
            a.whyrun "would assume #{@new_resource.source} would be have previously been made available"
          end
        end

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)
          @new_resource.version(nil)

          if @new_resource.source
            @package_source_found = ::File.exists?(@new_resource.source)
            if @package_source_found 
              Chef::Log.debug("#{@new_resource} checking pkg status")
              status = popen4("pkginfo -l -d #{@new_resource.source} #{@new_resource.package_name}") do |pid, stdin, stdout, stderr|
                stdout.each do |line|
                  case line
                  when /VERSION:\s+(.+)/
                    @new_resource.version($1)
                  end
                end
              end
            end
          end

          Chef::Log.debug("#{@new_resource} checking install state")
          status = popen4("pkginfo -l #{@current_resource.package_name}") do |pid, stdin, stdout, stderr|
            stdout.each do |line|
              case line
              when /VERSION:\s+(.+)/
                Chef::Log.debug("#{@new_resource} version #{$1} is already installed")
                @current_resource.version($1)
              end
            end
          end

          unless status.exitstatus == 0 || status.exitstatus == 1
            raise Chef::Exceptions::Package, "pkginfo failed - #{status.inspect}!"
          end

          unless @current_resource.version.nil?
            @current_resource.version(nil)
          end

          @current_resource
        end

        def candidate_version
          return @candidate_version if @candidate_version
          status = popen4("pkginfo -l -d #{@new_resource.source} #{new_resource.package_name}") do |pid, stdin, stdout, stderr|
            stdout.each_line do |line|
              case line
              when /VERSION:\s+(.+)/
                @candidate_version = $1
                @new_resource.version($1)
                Chef::Log.debug("#{@new_resource} setting install candidate version to #{@candidate_version}")
              end
            end
          end
          unless status.exitstatus == 0
            raise Chef::Exceptions::Package, "pkginfo -l -d #{@new_resource.source} - #{status.inspect}!"
          end
          @candidate_version
        end

        def install_package(name, version)
          Chef::Log.debug("#{@new_resource} package install options: #{@new_resource.options}")
          if @new_resource.options.nil?
            run_command_with_systems_locale(
                    :command => "pkgadd -n -d #{@new_resource.source} all"
                  )
            Chef::Log.debug("#{@new_resource} installed version #{@new_resource.version} from: #{@new_resource.source}")
          else
            run_command_with_systems_locale(
              :command => "pkgadd -n#{expand_options(@new_resource.options)} -d #{@new_resource.source} all"
            )
            Chef::Log.debug("#{@new_resource} installed version #{@new_resource.version} from: #{@new_resource.source}")
          end
        end

        def remove_package(name, version)
          if @new_resource.options.nil?
            run_command_with_systems_locale(
                    :command => "pkgrm -n #{name}"
                  )
            Chef::Log.debug("#{@new_resource} removed version #{@new_resource.version}")
          else
            run_command_with_systems_locale(
              :command => "pkgrm -n#{expand_options(@new_resource.options)} #{name}"
            )
            Chef::Log.debug("#{@new_resource} removed version #{@new_resource.version}")
          end
        end

      end
    end
  end
end
