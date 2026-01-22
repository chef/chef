#
#  Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
#
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
require_relative "../../json_compat"
require_relative "../../exceptions"
require_relative "../package"
# Bring in needed shared methods

class Chef
  class Provider
    class Package
      class Habitat < Chef::Provider::Package
        use_multipackage_api
        use "../../resource/habitat/habitat_shared"
        provides :habitat_package, target_mode: true

        def load_current_resource
          @current_resource = Chef::Resource::HabitatPackage.new(new_resource.name)
          current_resource.package_name(strip_version(new_resource.package_name))

          @candidate_version = candidate_versions
          current_resource.version(current_versions)

          current_resource
        end

        def define_resource_requirements
          super

          requirements.assert(:all_actions) do |a|
            a.assertion { !new_resource.environment }
            a.failure_message Chef::Exceptions::Package, "The environment property is not supported for package resources on this platform"
          end
        end

        def install_package(names, versions)
          # License acceptance needed outside of local Chef Client
          shell_out!("hab license accept") if Chef::Config.target_mode?

          names.zip(versions).map do |n, v|
            opts = ["pkg", "install", "--channel", new_resource.channel, "--url", new_resource.bldr_url]
            opts += ["--auth", new_resource.auth_token] if new_resource.auth_token
            opts += ["#{strip_version(n)}/#{v}", new_resource.options]
            opts += ["--binlink"] if new_resource.binlink
            opts += ["--force"] if new_resource.binlink.eql? :force
            hab(opts)
          end
        end

        alias_method :upgrade_package, :install_package

        def remove_package(names, versions)
          # raise 'It is too dangerous to :remove packages with the habitat_package resource right now. This functionality should be deferred to the hab cli.'
          names.zip(versions).map do |n, v|
            opts = %w{pkg uninstall}
            opts += ["--keep-latest", new_resource.keep_latest ] if new_resource.keep_latest
            opts += ["#{strip_version(n).chomp("/")}#{v}", new_resource.options]
            opts += ["--exclude"] if new_resource.exclude
            opts += ["--no-deps"] if new_resource.no_deps
            hab(opts)
            # action :remove
          end
        end

        alias_method :purge_package, :remove_package

        private

        def validate_name!(name)
          raise ArgumentError, "package name must be specified as 'origin/name', use the 'version' property to specify a version" unless name.squeeze("/").count("/") < 2
        end

        def strip_version(name)
          validate_name!(name)
          n = name.squeeze("/").chomp("/").sub(%r{^\/}, "")
          n = n[0..(n.rindex("/") - 1)] while n.count("/") >= 2
          n
        end

        def platform_target
          if windows?
            "target=x86_64-windows"
          else
            ""
          end
        end

        def depot_package(name, version = nil)
          @depot_package ||= {}
          @depot_package[name] ||=
            begin
              origin, pkg_name = name.split("/")
              name_version = [pkg_name, version].compact.join("/").squeeze("/").chomp("/").sub(%r{^\/}, "")
              url = if new_resource.bldr_url.include?("/v1/")
                      "#{new_resource.bldr_url.chomp("/")}/depot/channels/#{origin}/#{new_resource.channel}/pkgs/#{name_version}"
                    else
                      "#{new_resource.bldr_url.chomp("/")}/v1/depot/channels/#{origin}/#{new_resource.channel}/pkgs/#{name_version}"
                    end
              url << "/latest" unless name_version.count("/") >= 2
              url << "?#{platform_target}" unless platform_target.empty?

              headers = {}
              headers["Authorization"] = "Bearer #{new_resource.auth_token}" if new_resource.auth_token

              Chef::JSONCompat.parse(http.get(url, headers))
            rescue Net::HTTPClientException
              nil
            end
        end

        def package_version(name, version = nil)
          p = depot_package(name, version)
          "#{p["ident"]["version"]}/#{p["ident"]["release"]}" unless p.nil?
        end

        def http
          # FIXME: use SimpleJSON when the depot mime-type is fixed
          @http ||= TargetIO::HTTP.new(new_resource.bldr_url.to_s)
        end

        def candidate_versions
          package_name_array.zip(new_version_array).map do |n, v|
            package_version(n, v)
          end
        end

        def current_versions
          package_name_array.map do |n|
            installed_version(n)
          end
        end

        def installed_version(ident)
          hab("pkg", "path", ident).stdout.chomp.split(windows? ? "\\" : "/")[-2..-1].join("/")
        rescue Mixlib::ShellOut::ShellCommandFailed
          nil
        end

        # This is used by the superclass Chef::Provider::Package
        def version_requirement_satisfied?(current_version, new_version)
          return false if new_version.nil? || current_version.nil?

          nv_parts = new_version.squeeze("/").split("/")

          if nv_parts.count < 2
            current_version.squeeze("/").split("/")[0] == new_version.squeeze("/")
          else
            current_version.squeeze("/") == new_resource.version.squeeze("/")
          end
        end

        # This is used by the superclass Chef::Provider::Package
        def version_compare(v1, v2)
          require "mixlib/versioning" unless defined?(Mixlib::Versioning)
          # Convert the package version (X.Y.Z/DATE) into a version that Mixlib::Versioning understands (X.Y.Z+DATE)
          hab_v1 = Mixlib::Versioning.parse(v1.tr("/", "+"))
          hab_v2 = Mixlib::Versioning.parse(v2.tr("/", "+"))
          hab_v1 <=> hab_v2
        end
      end
    end
  end
end
