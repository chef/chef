#
# Author:: Jason K. Jackson (jasonjackson@gmail.com)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2009-2016, Jason K. Jackson
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
    # use the ifconfig resource to manage interfaces on *nix systems
    #
    # @example set a static ip on eth1
    #   ifconfig '33.33.33.80' do
    #     device 'eth1'
    #   end
    class Ifconfig < Chef::Resource
      resource_name :ifconfig

      state_attrs :inet_addr, :mask

      default_action :add
      allowed_actions :add, :delete, :enable, :disable

      property :target, String, name_property: true
      property :hwaddr, String
      property :mask, String
      property :inet_addr, String
      property :bcast, String
      property :mtu, String
      property :metric, String
      property :device, String, identity: true
      property :onboot, String
      property :network, String
      property :bootproto, String
      property :onparent, String
      property :ethtool_opts, String
      property :bonding_opts, String
      property :master, String
      property :slave, String
    end
  end
end
