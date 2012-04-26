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
        include Chef::Mixin::Command
        include Chef::Mixin::GetSourceFromPackage

        # def initialize(*args)
        #   super
        #   @current_resource = Chef::Resource::Package.new(@new_resource.name)
        # end

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)

          assert_install_action_requires_source!
          @new_resource.version candidate_version
          @current_resource.version installed_version
          @current_resource
        end


        def install_package(name, version)
          Chef::Log.debug("#{@new_resource} package install options: #{@new_resource.options}")
          if @new_resource.options.nil?
            shell_out_with_systems_locale!("pkgadd -n -d #{@new_resource.source} all")
          else
            shell_out_with_systems_locale!("pkgadd -n#{expand_options(@new_resource.options)} -d #{@new_resource.source} all")
          end
            Chef::Log.debug("#{@new_resource} installed version #{@new_resource.version} from: #{@new_resource.source}")
        end

        def remove_package(name, version)
          if @new_resource.options.nil?
            shell_out_with_systems_locale!("pkgrm -n #{name}")
          else
            shell_out_with_systems_locale!("pkgrm -n#{expand_options(@new_resource.options)} #{name}")
          end
          Chef::Log.debug("#{@new_resource} removed version #{@new_resource.version}")
        end

        def assert_install_action_requires_source!
          return if @new_resource.source || !Array(@new_resource.action).include?(:install)
          raise Chef::Exceptions::Package, "Source for package #{@new_resource.name} required for action install"
        end

        def assert_source_file_exists!
          return if ::File.exists?(@new_resource.source)
          raise Chef::Exceptions::Package, "Package #{@new_resource.name} not found: #{@new_resource.source}"
        end

        def candidate_version
          return @candidate_version if @candidate_version
          @candidate_version = source_version
        end

        def source_version
          return nil unless @new_resource.source
          assert_source_file_exists!

          Chef::Log.debug("#{@new_resource} checking pkg status")

          source_version_cmd = "pkginfo -l -d #{@new_resource.source} #{@new_resource.package_name}"
          status = shell_out!(source_version_cmd)
          raise Chef::Exceptions::Package, "#{source_version_cmd} - #{status.inspect}!" unless status.exitstatus == 0

          version_from_pkginfo(status.stdout)
        end

        def installed_version
          Chef::Log.debug("#{@new_resource} checking install state")
          status = shell_out!("pkginfo -l #{@current_resource.package_name}")

          raise Chef::Exceptions::Package, "pkginfo failed - #{status.inspect}!" unless status.exitstatus == 0 || status.exitstatus == 1

          version_from_pkginfo(status.stdout)
        end

        def version_from_pkginfo(pkginfo)
          pkginfo.each_line do |line|
            case line
            when /VERSION:\s+(.+)/
              Chef::Log.debug("#{@new_resource} version #{$1} is already installed")
              return $1
            end
          end
          return nil
        end

      end
    end
  end
end
