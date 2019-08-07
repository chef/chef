#
# Copyright:: Copyright 2016-2019, Chef Software Inc.
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
require_relative "../mixin/which"
require_relative "../mixin/shell_out"
require_relative "../dist"

class Chef
  class Resource
    class DnfPackage < Chef::Resource::Package
      extend Chef::Mixin::Which
      extend Chef::Mixin::ShellOut

      resource_name :dnf_package

      # all rhel variants >= 8 will use DNF
      provides :package, platform_family: "rhel", platform_version: ">= 8"

      # fedora >= 22 uses DNF
      provides :package, platform: "fedora", platform_version: ">= 22"

      # amazon will eventually use DNF
      provides :package, platform: "amazon" do
        which("dnf")
      end

      provides :dnf_package

      description "Use the dnf_package resource to install, upgrade, and remove packages with DNF for Fedora platforms. The dnf_package resource is able to resolve provides data for packages much like DNF can do when it is run from the command line. This allows a variety of options for installing packages, like minimum versions, virtual provides and library names."
      introduced "12.18"

      allowed_actions :install, :upgrade, :remove, :purge, :reconfig, :lock, :unlock, :flush_cache

      # Install a specific arch
      property :arch, [String, Array],
        description: "The architecture of the package to be installed or upgraded. This value can also be passed as part of the package name.",
        coerce: proc { |x| [x].flatten }

      # Flush the in-memory available/installed cache, this does not flush the dnf caches on disk
      property :flush_cache, Hash,
        description: "Flush the in-memory cache before or after a DNF operation that installs, upgrades, or removes a package. DNF automatically synchronizes remote metadata to a local cache. The #{Chef::Dist::CLIENT} creates a copy of the local cache, and then stores it in-memory during the #{Chef::Dist::CLIENT} run. The in-memory cache allows packages to be installed during the #{Chef::Dist::CLIENT} run without the need to continue synchronizing the remote metadata to the local cache while the #{Chef::Dist::CLIENT} run is in-progress.",
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
        unless arg.nil?
          Chef.deprecated(:dnf_package_allow_downgrade, "the allow_downgrade property on the dnf_package provider is not used, DNF supports downgrades by default.")
        end
        true
      end
    end
  end
end
