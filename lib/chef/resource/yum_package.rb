#
# Author:: AJ Christensen (<aj@chef.io>)
# Copyright:: Copyright 2008-2018, Chef Software Inc.
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
require_relative "../dist"

class Chef
  class Resource
    class YumPackage < Chef::Resource::Package
      resource_name :yum_package
      provides :package, platform_family: %w{rhel fedora amazon}

      description "Use the yum_package resource to install, upgrade, and remove packages with Yum"\
                  " for the Red Hat and CentOS platforms. The yum_package resource is able to resolve"\
                  " provides data for packages much like Yum can do when it is run from the command line."\
                  " This allows a variety of options for installing packages, like minimum versions,"\
                  " virtual provides, and library names."

      # XXX: the coercions here are due to the provider promiscuously updating the properties on the
      # new_resource which causes immutable modification exceptions when passed an immutable node array.
      #
      # <lecture>
      # THIS is why updating the new_resource in a provider is so terrible, and is equivalent to methods scribbling over
      # its own arguments as unintended side-effects (and why functional languages that don't allow modifcations
      # of variables eliminate entire classes of bugs).
      # </lecture>
      property :package_name, [ String, Array ],
               description: "One of the following: the name of a package, the name of a package and its architecture, the name of a dependency.",
               identity: true, coerce: proc { |x| x.is_a?(Array) ? x.to_a : x }

      property :version, [ String, Array ],
               description: "The version of a package to be installed or upgraded. This property is ignored when using the ':upgrade' action.",
               coerce: proc { |x| x.is_a?(Array) ? x.to_a : x }

      property :arch, [ String, Array ],
               description: "The architecture of the package to be installed or upgraded. This value can also be passed as part of the package name.",
               coerce: proc { |x| x.is_a?(Array) ? x.to_a : x }

      property :flush_cache, Hash,
               description: "Flush the in-memory cache before or after a Yum operation that installs, upgrades, or removes a package. Accepts a Hash in the form: { :before => true/false, :after => true/false } or an Array in the form [ :before, :after ].\nYum automatically synchronizes remote metadata to a local cache. The #{Chef::Dist::CLIENT} creates a copy of the local cache, and then stores it in-memory during the #{Chef::Dist::CLIENT} run. The in-memory cache allows packages to be installed during the #{Chef::Dist::CLIENT} run without the need to continue synchronizing the remote metadata to the local cache while the #{Chef::Dist::CLIENT} run is in-progress.",
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

      property :allow_downgrade, [ true, false ],
               description: "Downgrade a package to satisfy requested version requirements.",
               default: true,
               desired_state: false

      property :yum_binary, String
    end
  end
end
