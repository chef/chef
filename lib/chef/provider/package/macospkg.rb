#
# Author:: Joshua Timberman (<jtimberman@chef.io>)
# Author:: William Theaker (<william.theaker+chef@gusto.com>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../provider/package"
require_relative "package"

class Chef
  class Provider
    class MacosPkg < Chef::Provider::Package
      provides :macos_pkg

      def load_current_resource
        @current_resource = Chef::Resource::Package.new(new_resource.name)
        current_resource.package_name(new_resource.package_name)
        current_resource.version(get_current_version)
        logger.trace("#{new_resource} current package version: #{current_resource.version}") if current_resource.version

        current_resource
      end

      def get_current_version
        shell_out("pkgutil --pkg-info '#{new_resource.package_id}'").stdout.to_s[/version: (.*)/, 1]
      end

      def define_resource_requirements
        requirements.assert(:install) do |a|
          a.assertion { new_resource.source || new_resource.file }
          a.failure_message Chef::Exceptions::Package, "Must provide either a file or source property for #{new_resource.package_name} macos_pkg resource."
        end
      end

      def install_package(name, version)
        download_pkg if new_resource.source
        shell_out("installer -pkg #{pkg_file} -target #{new_resource.target}")
      end

      def upgrade_package(name, version)
        shell_out("pkgutil --forget '#{new_resource.package_id}'") if current_resource.version
        install_package(name, version)
      end

      def download_pkg
        @download_pkg ||= declare_resource(:remote_file, new_resource.name) do
          path default_download_cache_path
          source new_resource.source
          headers new_resource.headers if new_resource.headers
          checksum new_resource.checksum if new_resource.checksum
          backup false
        end
      end

      def pkg_file
        # @return [String] the path to the pkg file
        @pkg_file ||= if new_resource.file.nil?
                        uri = URI.parse(new_resource.source)
                        filename = ::File.basename(uri.path)
                        "#{Chef::Config[:file_cache_path]}/#{filename}"
                      else
                        new_resource.file
                      end
      end
    end
  end
end
