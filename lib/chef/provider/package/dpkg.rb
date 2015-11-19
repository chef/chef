#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Copyright:: Copyright (c) 2009 Bryan McLellan
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
      class Dpkg < Chef::Provider::Package
        DPKG_INSTALLED = /^Status: install ok installed/
        DPKG_VERSION = /^Version: (.+)$/

        provides :dpkg_package, os: "linux"

        include Chef::Mixin::GetSourceFromPackage

        def define_resource_requirements
          super

          requirements.assert(:install, :upgrade) do |a|
            a.assertion { !new_resource.source.nil? }
            a.failure_message Chef::Exceptions::Package, "#{new_resource} the source property is required for action :install or :upgrade"
          end

          requirements.assert(:install, :upgrade) do |a|
            a.assertion { source_file_exist? }
            a.failure_message Chef::Exceptions::Package, "#{new_resource} source file does not exist: #{new_resource.source}"
            a.whyrun "Assuming it would have been previously created."
          end
        end

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(new_resource.name)
          current_resource.package_name(new_resource.package_name)

          if source_file_exist?
            @candidate_version = get_candidate_version
            current_resource.package_name(get_package_name)
            # if the source file exists then our package_name is right
            current_resource.version(get_current_version)
          elsif !installing?
            # we can't do this if we're installing with no source, because our package_name
            # is probably not right.
            #
            # if we're removing or purging we don't use source, and our package_name must
            # be right so we can do this.
            #
            # we don't error here on the dpkg command since we'll handle the exception or
            # the why-run message in define_resource_requirements.
            current_resource.version(get_current_version)
          end

          current_resource
        end

        def install_package(name, version)
          Chef::Log.info("#{new_resource} installing #{new_resource.source}")
          run_noninteractive(
            "dpkg -i#{expand_options(new_resource.options)} #{new_resource.source}"
          )
        end

        def remove_package(name, version)
          Chef::Log.info("#{new_resource} removing #{new_resource.package_name}")
          run_noninteractive(
            "dpkg -r#{expand_options(new_resource.options)} #{new_resource.package_name}"
          )
        end

        def purge_package(name, version)
          Chef::Log.info("#{new_resource} purging #{new_resource.package_name}")
          run_noninteractive(
            "dpkg -P#{expand_options(new_resource.options)} #{new_resource.package_name}"
          )
        end

        def upgrade_package(name, version)
          install_package(name, version)
        end

        def preseed_package(preseed_file)
          Chef::Log.info("#{new_resource} pre-seeding package installation instructions")
          run_noninteractive("debconf-set-selections #{preseed_file}")
        end

        def reconfig_package(name, version)
          Chef::Log.info("#{new_resource} reconfiguring")
          run_noninteractive("dpkg-reconfigure #{name}")
        end

        private

        def get_current_version
          Chef::Log.debug("#{new_resource} checking install state")
          status = shell_out_with_timeout("dpkg -s #{current_resource.package_name}")
          package_installed = false
          status.stdout.each_line do |line|
            case line
            when DPKG_INSTALLED
              package_installed = true
            when DPKG_VERSION
              if package_installed
                Chef::Log.debug("#{new_resource} current version is #{$1}")
                return $1
              end
            end
          end
          return nil
        end

        # Runs command via shell_out_with_timeout with magic environment to disable
        # interactive prompts. Command is run with default localization rather
        # than forcing locale to "C", so command output may not be stable.
        def run_noninteractive(command)
          shell_out_with_timeout!(command, :env => { "DEBIAN_FRONTEND" => "noninteractive" })
        end

        def source_file_exist?
          new_resource.source && ::File.exist?(new_resource.source)
        end

        def pkginfo
          @pkginfo ||=
            begin
              Chef::Log.debug("#{new_resource} checking dpkg status")
              status = shell_out_with_timeout!("dpkg-deb -W #{new_resource.source}")
              status.stdout.split("\t")
            end
        end

        def get_candidate_version
          pkginfo[1].strip unless pkginfo.empty?
        end

        def get_package_name
          pkginfo[0] unless pkginfo.empty?
        end

        def installing?
          [:install, :upgrade].include?(action)
        end

      end
    end
  end
end
