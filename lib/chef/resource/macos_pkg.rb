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
  class Resource
    class MacosPkg < Chef::Resource::Package

      provides :macos_pkg

      description "Use the **macos_pkg** resource to install a macOS `.pkg` file, optionally downloading it from a remote source. A `package_id` property must be provided for idempotency. Either a `file` or `source` property is required."
      introduced "18.4"
      examples <<~DOC
        **Install osquery**:

        ```ruby
        macos_pkg 'osquery' do
          checksum   'a01d1f7da016f1e6bed54955e97982d491b7e55311433ff0fc985269160633af'
          package_id 'io.osquery.agent'
          source     'https://pkg.osquery.io/darwin/osquery-5.10.2.pkg'
          action     :install
        end
        ```
      DOC

      allowed_actions :install, upgrade

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
    end
  end
end
