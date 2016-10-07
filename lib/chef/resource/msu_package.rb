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

require "chef/resource/package"
require "chef/mixin/uris"

class Chef
  class Resource
    class MsuPackage < Chef::Resource::Package
      include Chef::Mixin::Uris

      provides :msu_package, os: "windows"

      allowed_actions :install, :remove

      def initialize(name, run_context = nil)
        super
        @resource_name = :msu_package
        @source = name
        @action = :install
      end

      property :source, String,
                coerce: (proc do |s|
                  unless s.nil?
                    uri_scheme?(s) ? s : Chef::Util::PathHelper.canonical_path(s, false)
                  end
                end)
      property :checksum, String, desired_state: false
    end
  end
end
