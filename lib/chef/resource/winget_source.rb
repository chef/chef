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
    class WingetSource < Chef::Resource
      unified_mode true

      provides(:winget_source) { true }

      description "Use the **winget_source** resource allows you to add/remove/update sources for your WinGet packages."
      introduced "17.20"
      examples <<~DOC
      **Add a package source to install from**

      ```ruby
      windows_package_manager "Add New Source" do
        source_name "my_package_source"
        url  https://foo/bar.com/packages
        action :register
      end
      ```

      **Remove a package source to install from**

      ```ruby
      windows_package_manager "Add New Source" do
        source_name "my_package_source"
        action :unregister
      end
      ```
      DOC

      property :source_name, String,
        description: "The name of a custom installation source.",
        default: "winget"

      property :url, String,
        description: "The url to a source"
    end
  end
end
