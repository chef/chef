#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright 2011 Opscode, Inc.
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

require 'chef/win32/error'

class Chef
  module Win32
    module Error
      class Win32APIError < Exception
        include Chef::Win32::Error

        def initialize(error_code)
          @error_code = error_code
        end

        attr_reader :error_code

        def message
          to_s
        end

        def to_s
          "Win32 ERROR #{error_code}: #{format_message(message_id: error_code).strip}"
        end
      end
    end
  end
end

