#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Author:: Mark Mzyk (<mmzyk@ospcode.com>)
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

require 'chef/win32/api/file'
require 'chef/win32/error'
require 'chef/win32/unicode'

class Chef
  module Win32
    class File
      class << self
        include Chef::Win32::API::File

        # Return true if the named file is a symbolic link, false otherwise.
        #
        # This method requires Windows Vista or later to work. Otherwise, it
        # always returns false as per MRI.
        #
        def symlink?(file_name)
          is_symlink = false
          path = ("\\\\?\\" << file_name).to_wstring
          if ((GetFileAttributesW(path) & FILE_ATTRIBUTE_REPARSE_POINT) > 0)
            find_file(path) do |handle, find_data|
              if find_data[:dw_reserved_0] == IO_REPARSE_TAG_SYMLINK
                is_symlink = true
              end
            end
          end
          is_symlink
        end

        private

        # retrieves a file search handle and passes it
        # to +&block+ along with the find_data.  also
        # ensures the handle is closed on exit of the block
        def find_file(path, &block)
          begin
            # check to see if the file is already UTF16-LE encoded`
            path = ("\\\\?\\" << path).to_wstring unless Chef::Win32::Unicode.utf16?(path)
            find_data = WIN32_FIND_DATA.new
            handle = FindFirstFileW(path, find_data)
            if handle == INVALID_HANDLE_VALUE
              Chef::Win32::Error.raise!
            end
            block.call(handle, find_data)
          ensure
            FindClose(handle) if handle && handle != INVALID_HANDLE_VALUE
          end
        end

      end

    end
  end
end
