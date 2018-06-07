# Author:: Dheeraj Dubey(dheeraj.dubey@msystechnologies.com)
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
    class PowershellPackage < Chef::Resource::Package
      include Chef::Mixin::Uris

      resource_name :powershell_package
      provides :powershell_package

      description "Use the powershell_package resource to install and manage packages via"\
                  " the Powershell Package Manager for the Microsoft Windows platform. The"\
                  " powershell_package resource requires administrative access, and a source"\
                  " must be configured in the Powershell Package Manager via the Register-PackageSource command"
      introduced "12.16"

      allowed_actions :install, :remove

      property :package_name, [String, Array], coerce: proc { |x| [x].flatten }
      property :version, [String, Array], coerce: proc { |x| [x].flatten }
      property :source, [String]
      property :skip_publisher_check, [true, false], default: false, introduced: "14.3", description: "Skip validating module author"
    end
  end
end
