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

require "chef/resource"

class Chef
  class Resource
    class Route < Chef::Resource
      default_action :add
      allowed_actions :add, :delete

      property :target, String, identity: true, name_property: true
      property :netmask, [String, nil]
      property :gateway, [String, nil]
      property :device, [String, nil], desired_state: false # Has a partial default in the provider of eth0.
      property :route_type, [:host, :net], default: :host, coerce: proc { |x| x.to_sym }, desired_state: false

      # I can find no evidence of these properties actually being used by Chef. NK 2017-04-11
      property :networking, [String, nil], desired_state: false
      property :networking_ipv6, [String, nil], desired_state: false
      property :hostname, [String, nil], desired_state: false
      property :domainname, [String, nil], desired_state: false
      property :domain, [String, nil], desired_state: false
      property :metric, [Integer, nil], desired_state: false
    end
  end
end
