#
# Copyright:: Copyright (c) Chef Software Inc.
# Copyright:: 2016-2020, Virender Khatri
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
      unified_mode true

      provides :habitat_package
      provides :package
      use "habitat_shared"
      description "Install the specified Habitat package from builder. Requires that Habitat is installed"
      examples <<~DOC
      ```ruby
      habitat_package 'core/redis'

      habitat_package 'core/redis' do
        version '3.2.3'
        channel 'unstable'
      end

      habitat_package 'core/redis' do
        version '3.2.3/20160920131015'
      end

      habitat_package 'core/nginx' do
        binlink :force
      end

      habitat_package 'core/nginx' do
        options '--binlink'
      end

      # Remove all
      habitat_package 'core/nginx'
        action :remove
      end

      # Remove specified
      habitat_package 'core/nginx/3.2.3'
        action :remove
      end

      # Remove but retain some versions (only available as of Habitat 1.5.86)
      habitat_package 'core/nginx'
        keep_latest '2'
        action :remove
      end

      # Remove but keep dependencies
      habitat_package 'core/nginx'
        no_deps false
        action :remove
      end
      ```
      DOC

      property :bldr_url, String, default: "https://bldr.habitat.sh"
      property :channel, String, default: "stable"
      property :auth_token, String
      property :binlink, [true, false, :force], default: false
      property :keep_latest, String
      property :exclude, String
      property :no_deps, [true, false], default: false
    end
  end
end
