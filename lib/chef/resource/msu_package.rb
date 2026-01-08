#
# Author:: Nimisha Sharad (<nimisha.sharad@msystechnologies.com>)
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
    class MsuPackage < Chef::Resource::Package
      include Chef::Mixin::Uris

      provides :msu_package

      description "Use the **msu_package** resource to install Microsoft Update(MSU) packages on Microsoft Windows machines."
      introduced "12.17"

      allowed_actions :install, :remove
      default_action :install

      property :package_name, String,
        description: "An optional property to set the package name if it differs from the resource block's name.",
        identity: true

      # This is the same property as the main package resource except it has the skip docs set to true
      # This resource abuses the package resource by storing the versions of all the cabs in the MSU file
      # in the version attribute from load current value even though those aren't technically the version of the
      # msu. Since the user wouldn't actually set this we don't want it on the docs site.
      property :version, [String, Array],
        skip_docs: true,
        description: "The version of a package to be installed or upgraded."

      property :source, String,
        description: "The local file path or URL for the MSU package.",
        coerce: (proc do |s|
          unless s.nil?
            uri_scheme?(s) ? s : Chef::Util::PathHelper.canonical_path(s, false)
          end
        end),
        default: lazy { package_name }

      property :checksum, String, desired_state: false,
               description: "SHA-256 digest used to verify the checksum of the downloaded MSU package."

      property :timeout, [String, Integer],
        default: 3600,
        description: "The amount of time (in seconds) to wait before timing out.",
        desired_state: false
    end
  end
end
