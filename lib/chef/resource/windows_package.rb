#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright 2014-2017, Chef Software Inc.
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

require "chef/mixin/uris"
require "chef/resource/package"
require "chef/provider/package/windows"
require "chef/win32/error" if RUBY_PLATFORM =~ /mswin|mingw|windows/

class Chef
  class Resource
    class WindowsPackage < Chef::Resource::Package
      include Chef::Mixin::Uris

      resource_name :windows_package
      provides :windows_package, os: "windows"
      provides :package, os: "windows"

      allowed_actions :install, :remove

      def initialize(name, run_context = nil)
        super
        @source ||= source(@package_name) if @package_name.downcase.end_with?(".msi")
      end

      # windows can't take array options yet
      property :options, String

      # Unique to this resource
      property :installer_type, Symbol
      property :timeout, [ String, Integer ], default: 600
      # In the past we accepted return code 127 for an unknown reason and 42 because of a bug
      property :returns, [ String, Integer, Array ], default: [ 0 ], desired_state: false
      property :source, String,
                coerce: (proc do |s|
                  unless s.nil?
                    uri_scheme?(s) ? s : Chef::Util::PathHelper.canonical_path(s, false)
                  end
                end)
      property :checksum, String, desired_state: false
      property :remote_file_attributes, Hash, desired_state: false
    end
  end
end
