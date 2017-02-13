#
# Author:: John Keiser (<jkeiser@chef.io>)
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright 2011-2016, Chef Software Inc.
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

require "chef/mixin/wide_string"
require "chef/win32/api/unicode"

class Chef
  module ReservedNames::Win32
    class Unicode
      include Chef::ReservedNames::Win32::API::Unicode
      extend Chef::ReservedNames::Win32::API::Unicode
    end
  end
end

module FFI
  class Pointer
    include Chef::Mixin::WideString

    def read_wstring(num_wchars = nil)
      if num_wchars.nil?
        # Find the length of the string
        length = 0
        last_char = nil
        while last_char != "\000\000"
          length += 1
          last_char = get_bytes(0, length * 2)[-2..-1]
        end

        num_wchars = length
      end

      wide_to_utf8(get_bytes(0, num_wchars * 2))
    end
  end
end

class String
  include Chef::Mixin::WideString

  def to_wstring
    utf8_to_wide(self)
  end
end
