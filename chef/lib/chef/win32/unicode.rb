#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
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

require 'chef/win32/api/unicode'

class Chef
  module Win32
    class Unicode

      class << self
        include Chef::Win32::API::Unicode

        def utf8_to_wide(ustring)
          # ensure it is actually UTF-8
          # Ruby likes to mark binary data as ASCII-8BIT
          ustring = (ustring + "").force_encoding('UTF-8') if ustring.respond_to?(:force_encoding) && ustring.encoding.name != "UTF-8"

          # ensure we have the double-null termination Windows Wide likes
          ustring = ustring << "\000\000" if ustring[-1].chr != "\000"

          # encode it all as UTF-16LE AKA Windows Wide Character AKA Windows Unicode
          ustring = begin
            if ustring.respond_to?(:encode)
              ustring.encode('UTF-16LE')
            else
              require 'iconv'
              Iconv.conv("UTF-16LE", "UTF-8", ustring)
            end
          end
          ustring
        end

        def wide_to_utf8(wstring)
          # ensure it is actually UTF-16LE
          # Ruby likes to mark binary data as ASCII-8BIT
          wstring = wstring.force_encoding('UTF-16LE') if wstring.respond_to?(:force_encoding)

          # encode it all as UTF-8
          wstring = begin
            if wstring.respond_to?(:encode)
              wstring.encode('UTF-8')
            else
              require 'iconv'
              Iconv.conv("UTF-8", "UTF-16LE", wstring)
            end
          end
          # remove trailing CRLF and NULL characters
          wstring.strip!
          wstring
        end
      end

    end
  end
end

module FFI
  class Pointer
    def read_wstring(num_wchars)
      Chef::Win32::Unicode.wide_to_utf8(self.get_bytes(0, num_wchars*2))
    end
  end
end

class String
  def to_wstring
    Chef::Win32::Unicode.utf8_to_wide(self)
  end
end
