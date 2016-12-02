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

class Chef
  class Resource
    class DnfPackage < Chef::Resource::Package
      extend Chef::Mixin::Which

      resource_name :dnf_package

      allowed_actions :install, :upgrade, :remove, :purge, :reconfig, :lock, :unlock, :flush_cache

      provides :package, os: "linux", platform_family: %w{rhel fedora} do
        which("dnf")
      end

      provides :dnf_package

      # Install a specific arch
      property :arch, [String, Array], coerce: proc { |x| [x].flatten }

      # Flush the in-memory available/installed cache, this does not flush the dnf caches on disk
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

      def allow_downgrade(arg = nil)
        if arg != nil
          Chef.deprecated(:dnf_package_allow_downgrade, "the allow_downgrade property on the dnf_package provider is not used, DNF supports downgrades by default.")
        end
        false
      end
    end
  end
end
