#
# Author:: Vasiliy Tolstov (<v.tolstov@selfip.ru>)
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
require_relative "../provider/package/paludis"

class Chef
  class Resource
    class PaludisPackage < Chef::Resource::Package

      provides :paludis_package, target_mode: true
      target_mode support: :full

      description "Use the **paludis_package** resource to manage packages for the Paludis platform."
      introduced "12.1"

      allowed_actions :install, :remove, :upgrade

      property :package_name, String,
        description: "An optional property to set the package name if it differs from the resource block's name.",
        identity: true

      property :version, String,
        description: "The version of a package to be installed or upgraded."

      property :timeout, [String, Integer],
        description: "The amount of time (in seconds) to wait before timing out.",
        default: 3600,
        desired_state: false
    end
  end
end
