#
# Author:: Joshua Timberman (<jtimberman@chef.io>)
# Author:: William Theaker (<william.theaker+chef@gusto.com>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "../resource"

class Chef
  class Resource
    class MacosPkg < Chef::Resource
      provides(:macos_pkg) { true }

      description "Use the **macos_pkg** resource to install a macOS `.pkg` file, optionally downloading it from a remote source. A `package_id` property must be provided for idempotency. Either a `file` or `source` property is required."
      introduced "18.1"
      examples <<~DOC
        **Install osquery**:

        ```ruby
        macos_pkg 'osquery' do
          checksum   '1fea8ac9b603851d2e76c5fc73138a468a3075a3002c8cb1fd7fff53b889c4dd'
          package_id 'io.osquery.agent'
          source     'https://pkg.osquery.io/darwin/osquery-5.8.2.pkg'
          action     :install
        end
        ```
      DOC

      allowed_actions :install
      default_action  :install

      property :checksum, String,
        description: "The sha256 checksum of the `.pkg` file to download."

      property :file, String,
        description: "The absolute path to the `.pkg` file on the local system."

      property :headers, Hash,
        description: "Allows custom HTTP headers (like cookies) to be set on the `remote_file` resource.",
        desired_state: false

      property :package_id, String,
        description: "The package ID registered with `pkgutil` when a `pkg` or `mpkg` is installed.",
        required: true

      property :source, String,
        description: "The remote URL used to download the `.pkg` file."

      property :target, String,
        description: "The device to install the package on.",
        default: "/"

      load_current_value do |new_resource|
        if shell_out("pkgutil --pkg-info '#{new_resource.package_id}'").exitstatus == 0
          Chef::Log.debug "#{new_resource.package_id} is already installed. To upgrade, try \"sudo pkgutil --forget '#{new_resource.package_id}'\""
        else
          current_value_does_not_exist!
        end
      end

      action :install, description: "Installs the pkg." do
        if new_resource.source.nil? && new_resource.file.nil?
          raise "Must provide either a file or source property for macos_pkg resources."
        end

        if current_resource.nil?
          if new_resource.source
            remote_file pkg_file do
              source new_resource.source
              headers new_resource.headers if new_resource.headers
              checksum new_resource.checksum if new_resource.checksum
            end
          end

          converge_by "install #{pkg_file}" do
            install_cmd = "installer -pkg #{pkg_file} -target #{new_resource.target}"

            execute install_cmd do
              action :run
            end
          end
        end
      end

      action_class do
        # @return [String] the path to the pkg file
        def pkg_file
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
end
