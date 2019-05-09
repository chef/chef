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

require_relative "package"
require_relative "../dist"

class Chef
  class Resource
    class GemPackage < Chef::Resource::Package
      resource_name :gem_package

      description "Use the gem_package resource to manage gem packages that are only included in recipes. When a package is installed from a local file, it must be added to the node using the remote_file or cookbook_file resources."

      # the source can either be a path to a package source like:
      #   source /var/tmp/mygem-1.2.3.4.gem
      # or it can be a url rubygems source like:
      #   https://www.rubygems.org
      # the default has to be nil in order for the magical wiring up of the name property to
      # the source pathname to work correctly.
      #
      # we don't do coercions here because its all a bit too complicated
      #
      # FIXME? the array form of installing paths most likely does not work?
      #
      property :source, [ String, Array ],
               description: "Optional. The URL, or list of URLs, at which the gem package is located. This list is added to the source configured in Chef::Config[:rubygems_url] (see also include_default_source) to construct the complete list of rubygems sources. Users in an 'airgapped' environment should set Chef::Config[:rubygems_url] to their local RubyGems mirror."

      property :clear_sources, [ TrueClass, FalseClass ],
               description: "Set to 'true' to download a gem from the path specified by the source property (and not from RubyGems).",
               default: lazy { Chef::Config[:clear_gem_sources] }, desired_state: false

      property :gem_binary, String, desired_state: false,
               description: "The path of a gem binary to use for the installation. By default, the same version of Ruby that is used by the #{Chef::Dist::CLIENT} will be installed."

      property :include_default_source, [ TrueClass, FalseClass ],
               description: "Set to 'false' to not include 'Chef::Config[:rubygems_url]'' in the sources.",
               default: true, introduced: "13.0"

      property :options, [ String, Hash, Array, nil ],
               description: "Options for the gem install, either a Hash or a String. When a hash is given, the options are passed to Gem::DependencyInstaller.new, and the gem will be installed via the gems API. When a String is given, the gem will be installed by shelling out to the gem command. Using a Hash of options with an explicit gem_binary will result in undefined behavior.",
               desired_state: false
    end
  end
end
