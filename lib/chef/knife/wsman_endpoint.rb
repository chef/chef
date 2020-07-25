#
# Author:: Steven Murawski (<smurawski@chef.io)
# Copyright:: Copyright (c) Chef Software, Inc.
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

class Chef
  class Knife
    class WsmanEndpoint
      attr_accessor :host
      attr_accessor :wsman_port
      attr_accessor :wsman_url
      attr_accessor :product_version
      attr_accessor :protocol_version
      attr_accessor :product_vendor
      attr_accessor :response_status_code
      attr_accessor :error_message

      def initialize(name, port, url)
        @host = name
        @wsman_port = port
        @wsman_url = url
      end

      def to_hash
        hash = {}
        instance_variables.each { |var| hash[var.to_s.delete("@")] = instance_variable_get(var) }
        hash
      end
    end
  end
end
