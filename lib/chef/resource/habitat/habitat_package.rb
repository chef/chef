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

require_relative "../package"

class Chef
  class Resource
    class HabitatPackage < Chef::Resource::Package

      provides :habitat_package, target_mode: true
      target_mode support: :full

      use "habitat_shared"
      description "Use the **habitat_package** to install or remove Chef Habitat packages from Habitat Builder."
      introduced "17.3"
      examples <<~DOC
      **Install core/redis**

      ```ruby
      habitat_package 'core/redis'
      ```

      **Install specific version of a package from the unstable channel**

      ```ruby
      habitat_package 'core/redis' do
        version '3.2.3'
        channel 'unstable'
      end
      ```

      **Install a package with specific version and revision**

      ```ruby
      habitat_package 'core/redis' do
        version '3.2.3/20160920131015'
      end
      ```

      **Install a package and force linking it's binary files to the system path**

      ```ruby
      habitat_package 'core/nginx' do
        binlink :force
      end
      ```

      **Install a package and link it's binary files to the system path**

      ```ruby
      habitat_package 'core/nginx' do
        options '--binlink'
      end
      ```

      **Remove package and all of it's versions**

      ```ruby
      habitat_package 'core/nginx'
        action :remove
      end
      ```

      **Remove specified version of a package**

      ```ruby
      habitat_package 'core/nginx/3.2.3'
        action :remove
      end
      ```

      **Remove package but retain some versions Note: Only available as of Habitat 1.5.86**

      ```ruby
      habitat_package 'core/nginx'
        keep_latest '2'
        action :remove
      end
      ```

      ```ruby
      **Remove package but keep dependencies**
      habitat_package 'core/nginx'
        no_deps false
        action :remove
      end
      ```
      DOC

      property :bldr_url, String, default: "https://bldr.habitat.sh",
      description: "The habitat builder url where packages will be downloaded from. **Defaults to public Habitat Builder**"

      property :channel, String, default: "stable",
      description: "The release channel to install your package from."

      property :auth_token, String,
      description: "Auth token for installing a package from a private organization on Habitat builder."

      property :binlink, [true, false, :force], default: false,
      description: "If habitat should attempt to binlink the package. Acceptable values: `true`, `false`, `:force`. Will fail on binlinking if set to `true` and binary or binlink exists."

      property :options, String,
      description: "Pass any additional parameters to the habitat package command."

      property :keep_latest, String,
      description: "Ability to uninstall while retaining a specified version **This feature only works in Habitat 1.5.86+.**"

      property :exclude, String,
      description: "Identifier of one or more packages that should not be uninstalled. (ex: core/redis, core/busybox-static/1.42.2/21120102031201)"

      property :no_deps, [true, false], default: false,
      description: "Remove package but retain dependencies."
    end
  end
end
