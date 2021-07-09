#
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../resource"

class Chef
  class Resource
    class ZypperRepository < Chef::Resource
      unified_mode true

      provides(:zypper_repository) { true }
      provides(:zypper_repo) { true } # legacy cookbook compatibility

      description "Use the **zypper_repository** resource to create Zypper package repositories on SUSE Enterprise Linux and openSUSE systems. This resource maintains full compatibility with the **zypper_repository** resource in the existing **zypper** cookbook."
      introduced "13.3"
      examples <<~DOC
        **Add the Apache repo on openSUSE Leap 15**:

        ```ruby
        zypper_repository 'apache' do
          baseurl 'http://download.opensuse.org/repositories/Apache'
          path '/openSUSE_Leap_15.2'
          type 'rpm-md'
          priority '100'
        end
        ```

        **Remove the repo named 'apache'**:

        ```ruby
        zypper_repository 'apache' do
          action :delete
        end
        ```

        **Refresh the repo named 'apache'**:

        ```ruby
        zypper_repository 'apache' do
          action :refresh
        end
        ```
      DOC

      property :repo_name, String,
        regex: [%r{^[^/]+$}],
        description: "An optional property to set the repository name if it differs from the resource block's name.",
        validation_message: "repo_name property cannot contain a forward slash `/`",
        name_property: true

      property :description, String,
        description: "The description of the repository that will be shown by the `zypper repos` command."

      property :type, String,
        description: "Specifies the repository type.",
        default: "NONE"

      property :enabled, [TrueClass, FalseClass],
        description: "Determines whether or not the repository should be enabled.",
        default: true

      property :autorefresh, [TrueClass, FalseClass],
        description: "Determines whether or not the repository should be refreshed automatically.",
        default: true

      property :gpgcheck, [TrueClass, FalseClass],
        description: "Determines whether or not to perform a GPG signature check on the repository.",
        default: true

      property :gpgkey, [String, Array],
        description: "The location of the repository key(s) to be imported.",
        coerce: proc { |v| Array(v) },
        default: []

      property :baseurl, String,
        description: "The base URL for the Zypper repository, such as `http://download.opensuse.org`."

      property :mirrorlist, String,
        description: "The URL of the mirror list that will be used."

      property :path, String,
        description: "The relative path from the repository's base URL."

      property :priority, Integer,
        description: "Determines the priority of the Zypper repository.",
        default: 99

      property :keeppackages, [TrueClass, FalseClass],
        description: "Determines whether or not packages should be saved.",
        default: false

      property :mode, [String, Integer],
        description: "The file mode of the repository file.",
        default: "0644"

      property :refresh_cache, [TrueClass, FalseClass],
        description: "Determines whether or not the package cache should be refreshed.",
        default: true

      property :source, String,
        description: "The name of the template for the repository file. Only necessary if you're using a custom template for the repository file."

      property :cookbook, String,
        description: "The cookbook to source the repository template file from. Only necessary if you're using a custom template for the repository file.",
        default: lazy { cookbook_name },
        default_description: "The cookbook containing the resource",
        desired_state: false

      property :gpgautoimportkeys, [TrueClass, FalseClass],
        description: "Automatically import the specified key when setting up the repository.",
        default: true

      default_action :create
      allowed_actions :create, :remove, :add, :refresh

      # provide compatibility with the zypper cookbook
      alias_method :key, :gpgkey
      alias_method :uri, :baseurl
    end
  end
end
