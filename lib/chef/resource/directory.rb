#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
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

require "chef/resource"
require "chef/mixin/securable"

class Chef
  class Resource
    class Directory < Chef::Resource
      resource_name :directory

      description "Use the directory resource to manage a directory, which is a hierarchy"\
                  " of folders that comprises all of the information stored on a computer."\
                  " The root directory is the top-level, under which the rest of the directory"\
                  " is organized. The directory resource uses the name property to specify the"\
                  " path to a location in a directory. Typically, permission to access that"\
                  " location in the directory is required."

      state_attrs :group, :mode, :owner

      include Chef::Mixin::Securable

      default_action :create
      allowed_actions :create, :delete

      property :path, String, name_property: true, identity: true
      property :recursive, [ TrueClass, FalseClass ], default: false
    end
  end
end
