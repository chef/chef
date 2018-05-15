#--
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software, Inc.
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

require "chef/http/authenticator"

class Chef
  module Formatters

    module APIErrorFormatting

      NETWORK_ERROR_CLASSES = [Errno::ECONNREFUSED, Timeout::Error, Errno::ETIMEDOUT, SocketError]

      def describe_network_errors(error_description)
        error_description.section("Networking Error:", <<-E)
#{exception.message}

Your chef_server_url may be misconfigured, or the network could be down.
E
        error_description.section("Relevant Config Settings:", <<-E)
chef_server_url  "#{server_url}"
E
      end

      def describe_eof_error(error_description)
        error_description.section("Authentication Error:", <<-E)
Received an EOF on transport socket.  This almost always indicates a network
error external to chef-client.  Some causes include:

  - Blocking ICMP Dest Unreachable (breaking Path MTU Discovery)
  - IPsec or VPN tunnelling / TCP Encapsulation MTU issues
  - Jumbo frames configured only on one side (breaking Path MTU)
  - Jumbo frames configured on a LAN that does not support them
  - Proxies or Load Balancers breaking large POSTs
  - Broken TCP offload in network drivers/hardware

Try sending large pings to the destination:

   windows:  ping server.example.com -f -l 9999
   unix:  ping server.example.com -s 9999

Try sending large POSTs to the destination (any HTTP code returned is success):

   e.g.:  curl http://server.example.com/`printf '%*s' 9999 '' | tr ' ' 'a'`

Try disabling TCP Offload Engines (TOE) in your ethernet drivers.

  windows:
    Disable-NetAdapterChecksumOffload * -TcpIPv4 -UdpIPv4 -IpIPv4 -NoRestart
    Disable-NetAdapterLso * -IPv4 -NoRestart
    Set-NetAdapterAdvancedProperty * -DisplayName "Large Receive Offload (IPv4)" -DisplayValue Disabled –NoRestart
    Restart-NetAdapter *
  unix(bash):
    for i in rx tx sg tso ufo gso gro lro rxvlan txvlan rxhash; do /sbin/ethtool -K eth0 $i off; done

In some cases the underlying virtualization layer (Xen, VMware, KVM, Hyper-V, etc) may have
broken virtual networking code.
        E
      end

      def describe_401_error(error_description)
        if clock_skew?
          error_description.section("Authentication Error:", <<-E)
Failed to authenticate to the chef server (http 401).
The request failed because your clock has drifted by more than 15 minutes.
Syncing your clock to an NTP Time source should resolve the issue.
E
        else
          error_description.section("Authentication Error:", <<-E)
Failed to authenticate to the chef server (http 401).
E

          error_description.section("Server Response:", format_rest_error)
          error_description.section("Relevant Config Settings:", <<-E)
chef_server_url   "#{server_url}"
node_name         "#{username}"
client_key        "#{api_key}"

If these settings are correct, your client_key may be invalid, or
you may have a chef user with the same client name as this node.
E
        end
      end

      def describe_400_error(error_description)
        error_description.section("Invalid Request Data:", <<-E)
The data in your request was invalid (HTTP 400).
E
        error_description.section("Server Response:", format_rest_error)
      end

      def describe_406_error(error_description, response)
        if response["x-ops-server-api-version"]
          version_header = Chef::JSONCompat.from_json(response["x-ops-server-api-version"])
          client_api_version = version_header["request_version"]
          min_server_version = version_header["min_version"]
          max_server_version = version_header["max_version"]

          error_description.section("Incompatible server API version:", <<-E)
This version of the API that this Chef request specified is not supported by the Chef server you sent this request to.
The server supports a min API version of #{min_server_version} and a max API version of #{max_server_version}.
Chef just made a request with an API version of #{client_api_version}.
Please either update your Chef client or server to be a compatible set.
E
        else
          describe_http_error(error_description)
        end
      end

      def describe_500_error(error_description)
        error_description.section("Unknown Server Error:", <<-E)
The server had a fatal error attempting to load the node data.
E
        error_description.section("Server Response:", format_rest_error)
      end

      def describe_503_error(error_description)
        error_description.section("Server Unavailable", "The Chef Server is temporarily unavailable")
        error_description.section("Server Response:", format_rest_error)
      end

      # Fallback for unexpected/uncommon http errors
      def describe_http_error(error_description)
        error_description.section("Unexpected API Request Failure:", format_rest_error)
      end

      # Parses JSON from the error response sent by Chef Server and returns the
      # error message
      def format_rest_error
        Array(Chef::JSONCompat.from_json(exception.response.body)["error"]).join("; ")
      rescue Exception
        safe_format_rest_error
      end

      def username
        config[:node_name]
      end

      def api_key
        config[:client_key]
      end

      def server_url
        config[:chef_server_url]
      end

      def clock_skew?
        exception.response.body =~ /synchronize the clock/i
      end

      def safe_format_rest_error
        # When we get 504 from the server, sometimes the response body is non-readable.
        #
        # Stack trace:
        #
        # NoMethodError: undefined method `closed?' for nil:NilClass
        # .../lib/ruby/1.9.1/net/http.rb:2789:in `stream_check'
        # .../lib/ruby/1.9.1/net/http.rb:2709:in `read_body'
        # .../lib/ruby/1.9.1/net/http.rb:2736:in `body'
        # .../lib/chef/formatters/error_inspectors/api_error_formatting.rb:91:in `rescue in format_rest_error'

        exception.response.body
      rescue Exception
        "Cannot fetch the contents of the response."
      end

    end
  end
end
