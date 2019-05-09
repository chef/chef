#
# Author:: Nimisha Sharad (<nimisha.sharad@msystechnologies.com>)
# Copyright:: Copyright 2008-2016, Chef Software, Inc.
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

      resource_name :msu_package
      provides :msu_package

      description "Use the msu_package resource to install Microsoft Update(MSU) packages on Microsoft Windows machines."
      introduced "12.17"

      allowed_actions :install, :remove
      default_action :install

      property :source, String,
               description: "The local file path or URL for the MSU package.",
               coerce: (proc do |s|
                 unless s.nil?
                   uri_scheme?(s) ? s : Chef::Util::PathHelper.canonical_path(s, false)
                 end
               end),
               default: lazy { |r| r.package_name }

      property :checksum, String, desired_state: false,
               description: "SHA-256 digest used to verify the checksum of the downloaded MSU package."
    end
  end
end
