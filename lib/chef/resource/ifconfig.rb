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

require_relative "../resource"

class Chef
  class Resource
    # @example set a static ip on eth1
    #   ifconfig '33.33.33.80' do
    #     device 'eth1'
    #   end
    class Ifconfig < Chef::Resource
      resource_name :ifconfig

      description "Use the ifconfig resource to manage interfaces on Unix and Linux systems."

      state_attrs :inet_addr, :mask

      default_action :add
      allowed_actions :add, :delete, :enable, :disable

      property :target, String,
               name_property: true,
               description: "The IP address that is to be assigned to the network interface. If not specified we'll use the resource's name."

      property :hwaddr, String,
               description: "The hardware address for the network interface."

      property :mask, String,
               description: "The decimal representation of the network mask. For example: 255.255.255.0."

      property :family, String, default: "inet",
               introduced: "14.0",
               description: "Networking family option for Debian-based systems. For example: inet or inet6."

      property :inet_addr, String,
               description: "The Internet host address for the network interface."

      property :bcast, String,
               description: "The broadcast address for a network interface. On some platforms this property is not set using ifconfig, but instead is added to the startup configuration file for the network interface."

      property :mtu, String,
               description: "The maximum transmission unit (MTU) for the network interface."

      property :metric, String,
               description: "The routing metric for the interface."

      property :device, String,
               identity: true,
               description: "The network interface to be configured."

      property :onboot, String,
               description: "Bring up the network interface on boot."

      property :network, String,
               description: "The address for the network interface."

      property :bootproto, String,
               description: "The boot protocol used by a network interface."

      property :onparent, String,
               description: "Bring up the network interface when its parent interface is brought up."

      property :ethtool_opts, String,
               introduced: "13.4",
               description: "Options to be passed to ethtool(8). For example: -A eth0 autoneg off rx off tx off."

      property :bonding_opts, String,
               introduced: "13.4",
               description: "Bonding options to pass via BONDING_OPTS on RHEL and CentOS. For example: mode=active-backup miimon=100."

      property :master, String,
               introduced: "13.4",
               description: "Specifies the channel bonding interface to which the Ethernet interface is linked."

      property :slave, String,
               introduced: "13.4",
               description: "When set to yes, this device is controlled by the channel bonding interface that is specified via the master property."

      property :vlan, String,
               introduced: "14.4",
               description: "The VLAN to assign the interface to."

      property :gateway, String,
               introduced: "14.4",
               description: "The gateway to use for the interface."
    end
  end
end
