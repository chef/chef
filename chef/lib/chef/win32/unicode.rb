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

      # Inspired by Windows::Unicode from 'windows-pr'
      # (C) 2006-2010, Daniel J. Berger
      # All Rights Reserved

      class << self
        include Chef::Win32::API::Unicode

        # Maps a character string to a UTF-16 (wide) character string using the
        # specified +encoding+.  If no encoding is specified, then CP_UTF8
        # is used if $KCODE (or the encoding name in Ruby 1.9.x) is set to UTF8.
        # Otherwise, CP_ACP is used.
        #
        def multi_to_wide(string, code_page=nil)
          return nil unless string
          raise TypeError unless string.is_a?(String)
          return string if IsTextUnicode(string, string.size, nil)
          code_page ||= default_code_page

          in_string = FFI::MemoryPointer.from_string(string)
          num_chars = MultiByteToWideChar(code_page, 0, in_string, -1, nil, 0)

          if num_chars > 0
            out_bytes = FFI::MemoryPointer.new num_chars*2
            MultiByteToWideChar(code_page, 0, in_string, -1, out_bytes, num_chars)
            out_bytes.get_bytes(0, num_chars*2)
          else
            Chef::Win32::Error.raise!
          end
        end

        # Maps a wide character string to a new character string using the
        # specified +encoding+. If no encoding is specified, then CP_UTF8
        # is used if $KCODE (or the encoding name in Ruby 1.9.x) is set to UTF8.
        # Otherwise, CP_ACP is used.
        #
        def wide_to_multi(wstring, code_page=nil)
          return nil unless wstring
          raise TypeError unless wstring.is_a?(String)
          # UTF-8 is desired just convert internally from UTF-16LE
          return utf16_to_utf8(wstring) if !code_page && utf8?
          code_page ||= default_code_page
          in_string = FFI::MemoryPointer.from_string(wstring)
          num_bytes = WideCharToMultiByte(code_page, 0, in_string, -1, nil, 0, nil, nil)

          if num_bytes > 0
            out_string = FFI::MemoryPointer.new num_bytes
            WideCharToMultiByte(code_page, 0, in_string, -1, out_string, num_bytes, nil, nil)
            out_string.read_string
          else
            Chef::Win32::Error.raise!
          end
        end

        private
        def default_code_page
          utf8? ? CP_UTF8 : CP_ACP
        end

        def default_ruby_encoding
          if "".respond_to?(:force_encoding) && defined?(Encoding)
            Encoding.default_external.to_s
          else
            $KCODE
          end
        end

        def utf8?
          %w{UTF-8 UTF8}.include?(default_ruby_encoding)
        end

        def utf16_to_utf8(string)
          if string.respond_to?(:force_encoding)
            string.force_encoding("UTF-16LE").encode("UTF-8")
          else
            require 'iconv'
            Iconv.conv("UTF-8", "UTF-16LE", string)
          end
        end
      end

    end
  end
end

module FFI
  class Pointer
    def read_wstring(num_wchars)
      Chef::Win32::Unicode.wide_to_multi(self.get_bytes(0, num_wchars*2))
    end
  end
end

class String
  def to_wstring
    Chef::Win32::Unicode.multi_to_wide(self)
  end
end
