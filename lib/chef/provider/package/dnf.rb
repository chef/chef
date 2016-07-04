# Copyright:: Copyright 2016, Chef Software, Inc.
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

require "chef/provider/package"
require "chef/resource/dnf_package"
require "chef/mixin/which"

class Chef
  class Provider
    class Package
      class Dnf < Chef::Provider::Package
        extend Chef::Mixin::Which

        use_multipackage_api

        provides :package, platform_family: %w{rhel fedora} do
          which("dnf")
        end

        provides :dnf_package, os: "linux"

        def load_current_resource
          @current_resource = Chef::Resource::DnfPackage.new(new_resource.name)
          current_resource.package_name(new_resource.package_name)

          current_resource.version(get_current_versions)

          current_resource
        end

        def candidate_version
          @candidate_version ||=
            begin
              @real_name = {}
              package_name_array.map do |package_name|
                provides = dnf("repoquery -q --whatprovides", package_name)
                version = nil
                real_name = ""
                provides.stdout.each_line do |line|
                  if line =~ /^(\S+)\-(\S+)\-(\S+)\.(\S+)/
                    real_name = $1
                    version = "#{$2}-#{$3}.#{$4}"
                  end
                end
                Chef::Log.debug("#{new_resource} found candidate_version of #{version.nil? ? "nil" : version} for #{real_name}")
                @real_name[package_name] = real_name
                version
              end
            end
        end

        def resolve_installed_version(pkg)
          query = rpm("--queryformat '%{EPOCHNUM}:%{VERSION}-%{RELEASE}.%{ARCH}\n' --whatprovides -q", pkg)
          if query.exitstatus != 0
            Chef::Log.debug("#{new_resource} did not find installed_version for #{pkg}")
            nil
          else
            version = query.stdout.chomp
            Chef::Log.debug("#{new_resource} found installed_version of #{version} for #{pkg}")
            version
          end
        end

        def get_current_versions
          package_name_array.map do |pkg|
            resolve_installed_version(pkg)
          end
        end

        def install_package(name, version)
          dnf(new_resource.options, "-y install", zip(name, version))
        end

        # dnf upgrade does not work on uninstalled packaged, while install will upgrade
        alias_method :upgrade_package, :install_package

        def remove_package(name, version)
          dnf(new_resource.options, "-y remove", zip(name, version))
        end

        alias_method :purge_package, :remove_package

        private

        def zip(names, versions)
          names.zip(versions).map do |n, v|
            (v.nil? || v.empty?) ? n : "#{@real_name[n]}-#{v}"
          end
        end

        def dnf(*args)
          shell_out_with_timeout!(a_to_s("dnf", *args))
        end

        def rpm(*args)
          shell_out_with_timeout(a_to_s("rpm", *args))
        end

      end
    end
  end
end
