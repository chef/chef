#
# Authors:: AJ Christensen (<aj@chef.io>)
#           Richard Manyanza (<liseki@nyikacraftsmen.com>)
#           Scott Bonds (<scott@ggr.com>)
# Copyright:: Copyright (c) Chef Software Inc.
# Copyright:: Copyright 2014-2016, Richard Manyanza, Scott Bonds
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
require_relative "../provider/package/openbsd"

class Chef
  class Resource
    class OpenbsdPackage < Chef::Resource::Package
      unified_mode true
      provides :openbsd_package
      provides :package, os: "openbsd"

      description "Use the **openbsd_package** resource to manage packages for the OpenBSD platform."
      introduced "12.1"
      examples <<~DOC
        **Install a package**

        ```ruby
        openbsd_package 'name of package' do
          action :install
        end
        ```

        **Remove a package**

        ```ruby
        openbsd_package 'name of package' do
          action :remove
        end
        ```
      DOC

      property :package_name, String,
        description: "An optional property to set the package name if it differs from the resource block's name.",
        identity: true

      property :version, String,
        description: "The version of a package to be installed or upgraded."
    end
  end
end
