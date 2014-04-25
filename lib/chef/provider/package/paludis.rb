#
# Author:: Vasiliy Tolstov (<v.tolstov@selfip.ru>)
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
      class Paludis < Chef::Provider::Package

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)

          @current_resource.version(nil)

          Chef::Log.debug("#{@new_resource} checking paludis for #{@new_resource.package_name}")
          cave = Mixlib::ShellOut.new("cave -L warning print-ids -m '*/#{@new_resource.package_name}::installed' -f '%v'")
          cave.run_command

          if  Object.const_defined? :Encoding
            if ( cave.encoding == Encoding::ASCII_8BIT &&
                 cave.encoding != Encoding.default_external &&
                 RUBY_VERSION.to_f < 2.0 )
              cave = cave.force_encoding(Encoding.default_external)
            end
          end

          cave.each do |version|
            Chef::Log.debug("#{@new_resource} current version is #{version}")
            @current_resource.version(version)
          end
          
          unless cave.exitstatus == 0 || cave.exitstatus == 1
            raise Chef::Exceptions::Package, "paludis failed - #{status.inspect}!"
          end

          @current_resource
        end


        def candidate_version
          return @candidate_version if @candidate_version

          cave = Mixlib::ShellOut.new("cave -L warning print-ids -s install -m '*/#{@new_resource.package_name.split('/').last}' -s install -f '%v'")
          cave.run_command

          if  Object.const_defined? :Encoding
            if ( cave.encoding == Encoding::ASCII_8BIT &&
                 cave.encoding != Encoding.default_external &&
                 RUBY_VERSION.to_f < 2.0 )
              cave = cave.force_encoding(Encoding.default_external)
            end
          end

          cave.each do |version|
            Chef::Log.debug("#{@new_resource} candidate version is #{version}")
            @candidate_version = version
          end
          
          unless status.exitstatus == 0 || status.exitstatus == 1
            raise Chef::Exceptions::Package, "paludis failed - #{status.inspect}!"
          end

          unless @candidate_version
            raise Chef::Exceptions::Package, "paludis does not have a version of package #{@new_resource.package_name}"
          end

          @candidate_version

        end


        def install_package(name, version)
          pkg = "=#{name}-#{version}"

          run_command_with_systems_locale(
            :command => "cave -L warning resolve -x #{expand_options(@new_resource.options)} #{pkg}"
          )
        end

        def upgrade_package(name, version)
          install_package(name, version)
        end

        def remove_package(name, version)
          if(version)
            pkg = "=#{@new_resource.package_name}-#{version}"
          else
            pkg = "#{@new_resource.package_name}"
          end

          run_command_with_systems_locale(
            :command => "cave -L warning uninstall -x #{expand_options(@new_resource.options)} #{pkg}"
          )
        end

        def purge_package(name, version)
          remove_package(name, version)
        end

      end
    end
  end
end
