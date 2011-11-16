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

require 'chef/win32/api/error'
require 'chef/win32/unicode'

class Chef
  module Win32

    class APIError < RuntimeError

      def initialize(error_code, error_message)
        @error_code = error_code
        @error_message = error_message
      end

      attr_reader :error_code, :error_message

      def message
        to_s
      end

      def to_s
        "#{error_code}: #{error_message}"
      end
    end

    module Error
      include Chef::Win32::API::Error

      def format_message(message_id = 0, args = {})
        flags = args[:flags] || FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ARGUMENT_ARRAY
        source = args[:source]
        language_id = args[:language_id] || 0
        varargs = args[:varargs] || [:int, 0]

        buffer = FFI::MemoryPointer.new :pointer
        num_chars = FormatMessageW(flags | FORMAT_MESSAGE_ALLOCATE_BUFFER, source, message_id, language_id, buffer, 0, *varargs)
        if num_chars == 0
          raise_last_error
        end

        # Extract the string
        begin
          return buffer.read_pointer.read_wstring(num_chars)
        ensure
          require 'chef/win32/memory'
          include Chef::Win32::Memory
          local_free(buffer.read_pointer)
        end
      end

      def get_last_error
        GetLastError()
      end

      def raise_last_error
        code = get_last_error
        message = format_message(code).strip
        raise Chef::Win32::APIError.new(code, message)
      end

      # TODO remove these if not needed
      # def IS_ERROR(status)
      #   status >> 31 == 1
      # end

      # def MAKE_HRESULT(sev, fac, code)
      #   sev << 31 | fac << 16 | code
      # end

      # def MAKE_SCODE(sev, fac, code)
      #   sev << 31 | fac << 16 | code
      # end

      # def HRESULT_CODE(hr)
      #   hr & 0xFFFF
      # end

      # def HRESULT_FACILITY(hr)
      #   (hr >> 16) & 0x1fff
      # end

      # def HRESULT_FROM_NT(x)
      #   x | 0x10000000 # FACILITY_NT_BIT
      # end

      # def HRESULT_FROM_WIN32(x)
      #   if x <= 0
      #     x
      #   else
      #     (x & 0x0000FFFF) | (7 << 16) | 0x80000000
      #   end
      # end

      # def HRESULT_SEVERITY(hr)
      #   (hr >> 31) & 0x1
      # end

      # def FAILED(status)
      #   status < 0
      # end

      # def SUCCEEDED(status)
      #   status >= 0
      # end
    end
  end
end
