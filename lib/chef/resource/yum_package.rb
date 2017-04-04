#
# Author:: AJ Christensen (<aj@chef.io>)
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
    class YumPackage < Chef::Resource::Package
      resource_name :yum_package
      provides :package, os: "linux", platform_family: %w{rhel fedora amazon}

      # XXX: the coercions here are due to the provider promiscuously updating the properties on the
      # new_resource which causes immutable modification exceptions when passed an immutable node array.
      #
      # <lecture>
      # THIS is why updating the new_resource in a provider is so terrible, and is equivalent to methods scribbling over
      # its own arguments as unintended side-effects (and why functional languages that don't allow modifcations
      # of variables eliminate entire classes of bugs).
      # </lecture>
      property :package_name, [ String, Array ], identity: true, coerce: proc { |x| x.is_a?(Array) ? x.to_a : x }
      property :version, [ String, Array ], coerce: proc { |x| x.is_a?(Array) ? x.to_a : x }
      property :arch, [ String, Array ], coerce: proc { |x| x.is_a?(Array) ? x.to_a : x }

      property :flush_cache,
        Hash,
        default: { before: false, after: false },
        coerce: proc { |v|
          if v.is_a?(Hash)
            v
          elsif v.is_a?(Array)
            v.each_with_object({}) { |arg, obj| obj[arg] = true }
          elsif v.is_a?(TrueClass) || v.is_a?(FalseClass)
            { before: v, after: v }
          elsif v == :before
            { before: true, after: false }
          elsif v == :after
            { after: true, before: false }
          end
        }

      property :allow_downgrade, [ true, false ], default: false

      property :yum_binary, String
    end
  end
end
