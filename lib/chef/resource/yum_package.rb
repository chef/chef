#
# Author:: AJ Christensen (<aj@chef.io>)
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
require "chef/provider/package/yum"

class Chef
  class Resource
    class YumPackage < Chef::Resource::Package
      resource_name :yum_package
      provides :package, os: "linux", platform_family: %w{rhel fedora}

      # Install a specific arch
      property :arch, [ String, Array ]
      # the {} on the proc here is because rspec chokes if it's do...end
      property :flush_cache,
               Hash,
               default: { before: false, after: false },
               coerce: proc { |v|
                 if v.is_a?(Array)
                   v.each_with_object({}) { |arg, obj| obj[arg] = true }
                 elsif v.any?
                   v
                 else
                   { before: v, after: v }
                 end
               }
      property :allow_downgrade, [ true, false ], default: false
      property :yum_binary, String

    end
  end
end
