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
require 'chef/win32/api/security'
require 'chef/win32/error'

class Chef
  module Win32
    class File
      include Chef::Win32::API::File
      extend Chef::Win32::API::File

      # Creates a symbolic link called +new_name+ for the file or directory
      # +old_name+.
      #
      # This method requires Windows Vista or later to work. Otherwise, it
      # returns nil as per MRI.
      #
      def self.link(old_name, new_name)
        raise Errno::ENOENT, "(#{old_name}, #{new_name})" unless ::File.exist?(old_name)
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
      def self.symlink(old_name, new_name)
        raise Errno::ENOENT, "(#{old_name}, #{new_name})" unless ::File.exist?(old_name)
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
      def self.symlink?(file_name)
        is_symlink = false
        path = encode_path(file_name)
        if ::File.exists?(file_name)
          if ((GetFileAttributesW(path) & FILE_ATTRIBUTE_REPARSE_POINT) > 0)
            file_search_handle(file_name) do |handle, find_data|
              if find_data[:dw_reserved_0] == IO_REPARSE_TAG_SYMLINK
                is_symlink = true
              end
            end
          end
        end
        is_symlink
      end

      # Returns the path of the of the symbolic link referred to by +file+.
      #
      # Requires Windows Vista or later. On older versions of Windows it
      # will raise a NotImplementedError, as per MRI.
      #
      def self.readlink(link_name)
        raise Errno::ENOENT, link_name unless ::File.exist?(link_name)
        # TODO do a check for GetFinalPathNameByHandleW and
        # raise NotImplemented exception on older Windows
        file_handle(link_name) do |handle|
          buffer = FFI::MemoryPointer.new(0.chr * MAX_PATH)
          num_chars = GetFinalPathNameByHandleW(handle, buffer, buffer.size, FILE_NAME_NORMALIZED)
          if num_chars == 0
            Chef::Win32::Error.raise! #could be misleading if problem is too small buffer size as GetLastError won't report failure
          end
          buffer.read_wstring(num_chars).sub(path_prepender, "")
        end
      end

      def self.info(file_name)
        Info.new(file_name)
      end

      # ::File compat
      class << self
        alias :stat :info
      end

    end
  end
end

require 'chef/win32/file/info'
