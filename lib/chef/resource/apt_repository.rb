#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: 2016-2017, Chef Software, Inc.
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

require "chef/resource"

class Chef
  class Resource
    class AptRepository < Chef::Resource
      resource_name :apt_repository
      provides(:apt_repository) { true }

      description "Use the apt_repository resource to specify additional APT repositories."\
                  " Adding a new repository will update APT package cache immediately."
      introduced "12.9"

      # There's a pile of [ String, nil, FalseClass ] types in these properties.
      # This goes back to Chef 12 where String didn't default to nil and we had to do
      # it ourself, which required allowing that type as well. We've cleaned up the
      # defaults, but since we allowed users to pass nil here we need to continue
      # to allow that so don't refactor this however tempting it is
      property :repo_name, String,
               regex: [/^[^\/]+$/],
               validation_message: "repo_name property cannot contain a forward slash '/'",
               name_property: true

      property :uri, String
      property :distribution, [ String, nil, FalseClass ], default: lazy { node["lsb"]["codename"] }
      property :components, Array, default: lazy { [] }
      property :arch, [String, nil, FalseClass]
      property :trusted, [TrueClass, FalseClass], default: false
      # whether or not to add the repository as a source repo, too
      property :deb_src, [TrueClass, FalseClass], default: false
      property :keyserver, [String, nil, FalseClass], default: "keyserver.ubuntu.com"
      property :key, [String, Array, nil, FalseClass], default: lazy { [] }, coerce: proc { |x| x ? Array(x) : x }
      property :key_proxy, [String, nil, FalseClass]

      property :cookbook, [String, nil, FalseClass], desired_state: false
      property :cache_rebuild, [TrueClass, FalseClass], default: true, desired_state: false

      default_action :add
      allowed_actions :add, :remove
    end
  end
end
