#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2009-2016, Bryan McLellan
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

require_relative "../resource"

class Chef
  class Resource
    class Route < Chef::Resource
      default_action :add
      allowed_actions :add, :delete

      description "Use the route resource to manage the system routing table in a Linux environment."

      property :target, String,
               description: "The IP address of the target route.",
               identity: true, name_property: true

      property :comment, [String, nil],
               description: "Add a comment for the route.",
               introduced: "14.0"

      property :metric, [Integer, nil],
               description: "The route metric value."

      property :netmask, [String, nil],
               description: "The decimal representation of the network mask. For example: 255.255.255.0."

      property :gateway, [String, nil],
               description: "The gateway for the route."

      property :device, [String, nil],
               description: "The network interface to which the route applies.",
               desired_state: false # Has a partial default in the provider of eth0.

      property :route_type, [Symbol, String],
               description: "",
               equal_to: [:host, :net], default: :host, desired_state: false
    end
  end
end
