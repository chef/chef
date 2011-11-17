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

class Chef
  module Win32
    class File
      class << self
        include Chef::Win32::API::File

        def symlink?(file_name)
          symlink = false
          path = ("\\\\?\\" << file_name).to_wstring
          out = GetFileAttributesW(path)
          if out == INVALID_FILE_ATTRIBUTES
            Chef::Win32::Error.raise!
          end
          if ((out & FILE_ATTRIBUTE_REPARSE_POINT) != 0)
            find_data = WIN32_FIND_DATA.new
            handle = FindFirstFileW(path, find_data)
            if handle == INVALID_HANDLE_VALUE
              Chef::Win32::Error.raise!
            end
            if find_data[:dw_reserved_0] == IO_REPARSE_TAG_SYMLINK
              symlink = true
            end
          end
          symlink
        end

      end

    end
  end
end
