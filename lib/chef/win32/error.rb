#
# Author:: John Keiser (<jkeiser@chef.io>)
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

require "chef/win32/api/error"
require "chef/win32/memory"
require "chef/win32/unicode"
require "chef/exceptions"

class Chef
  module ReservedNames::Win32
    class Error
      include Chef::ReservedNames::Win32::API::Error
      extend Chef::ReservedNames::Win32::API::Error

      def self.format_message(message_id = 0, args = {})
        flags = args[:flags] || FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ARGUMENT_ARRAY
        flags |= FORMAT_MESSAGE_ALLOCATE_BUFFER
        source = args[:source] || 0
        language_id = args[:language_id] || 0
        varargs = args[:varargs] || [:int, 0]
        buffer = FFI::MemoryPointer.new :pointer
        num_chars = FormatMessageW(flags, source, message_id, language_id, buffer, 0, *varargs)
        if num_chars == 0
          source = LoadLibraryExW("netmsg.dll".to_wstring, 0, LOAD_LIBRARY_AS_DATAFILE)
          begin
            num_chars = FormatMessageW(flags | FORMAT_MESSAGE_FROM_HMODULE, source, message_id, language_id, buffer, 0, *varargs)
          ensure
            FreeLibrary(source)
          end
        end

        if num_chars == 0
          raise!
        end

        # Extract the string
        begin
          return buffer.read_pointer.read_wstring(num_chars)
        ensure
          Chef::ReservedNames::Win32::Memory.local_free(buffer.read_pointer)
        end
      end

      def self.get_last_error
        FFI::LastError.error
      end

      # Raises the last error.  This should only be called by
      # Win32 API wrapper functions, and then only when wrapped
      # in an if() statement (since it unconditionally exits)
      # === Returns
      # nil::: always returns nil when it does not raise
      # === Raises
      # Chef::Exceptions::Win32APIError:::
      def self.raise!(message = nil, code = get_last_error)
        msg = format_message(code).strip
        if code == ERROR_USER_NOT_FOUND
          raise Chef::Exceptions::UserIDNotFound, msg
        else
          formatted_message = ""
          formatted_message << message if message
          formatted_message << "---- Begin Win32 API output ----\n"
          formatted_message << "System Error Code: #{code}\n"
          formatted_message << "System Error Message: #{msg}\n"
          formatted_message << "---- End Win32 API output ----\n"
          raise Chef::Exceptions::Win32APIError, msg + "\n" + formatted_message
        end
      end
    end
  end
end
