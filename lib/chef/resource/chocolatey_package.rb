#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

class Chef
  class Resource
    class ChocolateyPackage < Chef::Resource::Package

      provides :chocolatey_package, os: "windows"

      allowed_actions :install, :upgrade, :remove, :uninstall, :purge, :reconfig

      def initialize(name, run_context = nil)
        super
        @resource_name = :chocolatey_package
      end

      # windows can't take Array options yet
      property :options, String

      property :package_name, [String, Array], coerce: proc { |x| [x].flatten }

      property :version, [String, Array], coerce: proc { |x| [x].flatten }
      property :returns, [Integer, Array], default: [ 0 ], desired_state: false
    end
  end
end
