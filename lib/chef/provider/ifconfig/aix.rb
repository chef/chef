#
# Author:: Kaustubh Deorukhkar (kaustubh@clogeny.com)
# Copyright:: Copyright (c) 2013 Opscode, Inc
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

require 'chef/provider/ifconfig'

class Chef
  class Provider
    class Ifconfig
      class Aix < Chef::Provider::Ifconfig

        def load_current_resource
          @current_resource = Chef::Resource::Ifconfig.new(@new_resource.name)

          @interface_exists = false
          found_interface = false
          interface = {}

          @status = popen4("ifconfig -a") do |pid, stdin, stdout, stderr|
            stdout.each do |line|

              if !found_interface
                if line =~ /^(\S+):\sflags=(\S+)/
                  # We have interface name, if this is the interface for @current_resource, load info else skip till next interface is found.
                  if $1 == @new_resource.device
                    # Found interface
                    found_interface = true
                    @interface_exists = true
                    @current_resource.target(@new_resource.target)
                    @current_resource.device($1)
                    interface[:flags] = $2
                    @current_resource.metric($1) if line =~ /metric\s(\S+)/
                  end
                end
              else
                # parse interface related information, stop when next interface is found.
                if line =~ /^(\S+):\sflags=(\S+)/
                  # we are done parsing interface info and hit another one, so stop.
                  found_interface = false
                  break
                else
                  if found_interface
                    # read up interface info
                    @current_resource.inet_addr($1) if line =~ /inet\s(\S+)\s/
                    @current_resource.bcast($1) if line =~ /broadcast\s(\S+)/
                    @current_resource.mask(hex_to_dec_netmask($1)) if line =~ /netmask\s(\S+)\s/ # TODO - convert hex to dec
                    # TODO @current_resource.mtu = lsattr -EO -a mtu -l <interface>
                  end
                end
              end
            end
          end

          @current_resource
        end

        private
        # add can be used in two scenarios, add first inet addr or add VIP
        # http://www-01.ibm.com/support/docview.wss?uid=swg21294045
        def add_command
          # ifconfig changes are temporary, chdev persist across reboots.
          if @current_resource.inet_addr
            # adding a VIP
            command = "chdev -l #{@new_resource.device}  -a alias4=#{@new_resource.name}"
            command << ",#{@new_resource.mask}" if @new_resource.mask
          else
            command = "chdev -l #{@new_resource.device} -a netaddr=#{@new_resource.name}"
            command << " -a netmask=#{@new_resource.mask}" if @new_resource.mask
            # TODO - how to? chdev fails, ifconfig effect is till reboot.
            # command << " -a metric=#{@new_resource.metric}" if @new_resource.metric
            command << " -a mtu=#{@new_resource.mtu}" if @new_resource.mtu
          end
          command
        end

        def enable_command
          if @current_resource.inet_addr
            # add alias
            command = "ifconfig #{@new_resource.device} inet #{@new_resource.name}"
            command << " netmask #{@new_resource.mask}" if @new_resource.mask
            command << " metric #{@new_resource.metric}" if @new_resource.metric
            command << " mtu #{@new_resource.mtu}" if @new_resource.mtu
            command << " alias"
          else
            command = super  
          end
          command
        end

        def disable_command
          if @new_resource.is_vip
            "ifconfig #{@new_resource.device} inet #{@new_resource.name} delete"
          else
            super
          end
        end

        def delete_command
          # ifconfig changes are temporary, chdev persist across reboots.
          "chdev -l #{@new_resource.device} -a state=down"
        end

        def delete_vip_command
          command = "chdev -l #{@new_resource.device}  -a delalias4=#{@new_resource.name}"
          command << ",#{@new_resource.mask}" if @new_resource.mask
          command
        end

        def hex_to_dec_netmask(netmask)
          # example '0xffff0000' -> '255.255.0.0'
          dec = netmask[2..3].to_i(16).to_s(10)
          [4,6,8].each { |n| dec = dec + "." + netmask[n..n+1].to_i(16).to_s(10) }
          dec
        end

      end
    end
  end
end
