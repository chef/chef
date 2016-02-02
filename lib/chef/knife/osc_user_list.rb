#
# Author:: Steven Danna (<steve@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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

require "chef/knife"

# DEPRECATION NOTE
# This code only remains to support users still operating with
# Open Source Chef Server 11 and should be removed once support
# for OSC 11 ends. New development should occur in user_list.rb.

class Chef
  class Knife
    class OscUserList < Knife

      deps do
        require "chef/user"
        require "chef/json_compat"
      end

      banner "knife osc_user list (options)"

      option :with_uri,
        :short => "-w",
        :long => "--with-uri",
        :description => "Show corresponding URIs"

      def run
        output(format_list_for_display(Chef::User.list))
      end
    end
  end
end
