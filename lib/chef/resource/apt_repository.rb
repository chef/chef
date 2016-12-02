#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: Copyright (c) 2016 Chef Software, Inc.
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
      provides :apt_repository

      property :repo_name, String, name_property: true
      property :uri, String
      property :distribution, [ String, nil, false ], default: lazy { node["lsb"]["codename"] }, nillable: true, coerce: proc { |x| x ? x : nil }
      property :components, Array, default: []
      property :arch, [String, nil, false], default: nil, nillable: true, coerce: proc { |x| x ? x : nil }
      property :trusted, [TrueClass, FalseClass], default: false
      # whether or not to add the repository as a source repo, too
      property :deb_src, [TrueClass, FalseClass], default: false
      property :keyserver, [String, nil, false], default: "keyserver.ubuntu.com", nillable: true, coerce: proc { |x| x ? x : nil }
      property :key, [String, nil, false], default: nil, nillable: true, coerce: proc { |x| x ? x : nil }
      property :key_proxy, [String, nil, false], default: nil, nillable: true, coerce: proc { |x| x ? x : nil }

      property :cookbook, [String, nil, false], default: nil, desired_state: false, nillable: true, coerce: proc { |x| x ? x : nil }
      property :cache_rebuild, [TrueClass, FalseClass], default: true, desired_state: false

      default_action :add
      allowed_actions :add, :remove
    end
  end
end
