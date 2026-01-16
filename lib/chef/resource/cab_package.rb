#
# Author:: Vasundhara Jagdale (<vasundhara.jagdale@msystechnologies.com>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "package"
require_relative "../mixin/uris"

class Chef
  class Resource
    class CabPackage < Chef::Resource::Package
      include Chef::Mixin::Uris

      provides :cab_package

      description "Use the **cab_package** resource to install or remove Microsoft Windows cabinet (.cab) packages."
      introduced "12.15"
      examples <<~'DOC'
      **Using local path in source**

      ```ruby
      cab_package 'Install .NET 3.5 sp1 via KB958488' do
        source 'C:\Users\xyz\AppData\Local\Temp\Windows6.1-KB958488-x64.cab'
        action :install
      end

      cab_package 'Remove .NET 3.5 sp1 via KB958488' do
        source 'C:\Users\xyz\AppData\Local\Temp\Windows6.1-KB958488-x64.cab'
        action :remove
      end
      ```

      **Using URL in source**

      ```ruby
      cab_package 'Install .NET 3.5 sp1 via KB958488' do
        source 'https://s3.amazonaws.com/my_bucket/Windows6.1-KB958488-x64.cab'
        action :install
      end

      cab_package 'Remove .NET 3.5 sp1 via KB958488' do
        source 'https://s3.amazonaws.com/my_bucket/Temp\Windows6.1-KB958488-x64.cab'
        action :remove
      end
      ```
      DOC

      allowed_actions :install, :remove

      property :package_name, String,
        description: "An optional property to set the package name if it differs from the resource block's name.",
        identity: true

      property :version, String,
        description: "The version of a package to be installed or upgraded."

      property :source, String,
        description: "The local file path or URL for the CAB package.",
        coerce: (proc do |s|
          unless s.nil?
            uri_scheme?(s) ? s : Chef::Util::PathHelper.canonical_path(s, false)
          end
        end),
        default: lazy { package_name }, default_description: "The package name."
    end
  end
end
