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

        # Creates a symbolic link called +new_name+ for the file or directory
        # +old_name+.
        #
        # This method requires Windows Vista or later to work. Otherwise, it
        # returns nil as per MRI.
        #
        def link(old_name, new_name)
          # TODO do a check for CreateHardLinkW and
          # raise NotImplemented exception on older Windows
          old_name = encode_path(old_name)
          new_name = encode_path(new_name)
          unless CreateHardLinkW(new_name, old_name, nil)
            Chef::Win32::Error.raise!
          end
        end

        # Creates a symbolic link called +new_name+ for the file or directory
        # +old_name+.
        #
        # This method requires Windows Vista or later to work. Otherwise, it
        # returns nil as per MRI.
        #
        def symlink(old_name, new_name)
          # TODO do a check for CreateSymbolicLinkW and
          # raise NotImplemented exception on older Windows
          flags = ::File.directory?(old_name) ? SYMBOLIC_LINK_FLAG_DIRECTORY : 0
          old_name = encode_path(old_name)
          new_name = encode_path(new_name)
          unless CreateSymbolicLinkW(new_name, old_name, flags)
            Chef::Win32::Error.raise!
          end
        end

        # Return true if the named file is a symbolic link, false otherwise.
        #
        # This method requires Windows Vista or later to work. Otherwise, it
        # always returns false as per MRI.
        #
        def symlink?(file_name)
          is_symlink = false
          path = encode_path(file_name)
          if ((GetFileAttributesW(path) & FILE_ATTRIBUTE_REPARSE_POINT) > 0)
            find_file(file_name) do |handle, find_data|
              if find_data[:dw_reserved_0] == IO_REPARSE_TAG_SYMLINK
                is_symlink = true
              end
            end
          end
          is_symlink
        end

        private

        # takes the given path pre-pends "\\?\" and
        # UTF-16LE encodes it.  Used to prepare paths
        # to be passed to the *W vesion of WinAPI File
        # functions
        def encode_path(path)
          ("\\\\?\\" << path).to_wstring
        end

        # retrieves a file search handle and passes it
        # to +&block+ along with the find_data.  also
        # ensures the handle is closed on exit of the block
        def find_file(path, &block)
          begin
            path = encode_path(path)
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
