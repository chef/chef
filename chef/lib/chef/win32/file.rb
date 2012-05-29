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
  module ReservedNames::Win32
    class File
      include Chef::ReservedNames::Win32::API::File
      extend Chef::ReservedNames::Win32::API::File

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
          Chef::ReservedNames::Win32::Error.raise!
        end
      end

      # Creates a symbolic link called +new_name+ for the file or directory
      # +old_name+.
      #
      # This method requires Windows Vista or later to work. Otherwise, it
      # returns nil as per MRI.
      #
      def self.symlink(old_name, new_name)
        # raise Errno::ENOENT, "(#{old_name}, #{new_name})" unless ::File.exist?(old_name)
        # TODO do a check for CreateSymbolicLinkW and
        # raise NotImplemented exception on older Windows
        flags = ::File.directory?(old_name) ? SYMBOLIC_LINK_FLAG_DIRECTORY : 0
        old_name = encode_path(old_name)
        new_name = encode_path(new_name)
        unless CreateSymbolicLinkW(new_name, old_name, flags)
          Chef::ReservedNames::Win32::Error.raise!
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
        raise Errno::ENOENT, link_name unless ::File.exists?(link_name)
        symlink_file_handle(link_name) do |handle|
          # Go to DeviceIoControl to get the symlink information
          # http://msdn.microsoft.com/en-us/library/windows/desktop/aa364571(v=vs.85).aspx
          reparse_buffer = FFI::MemoryPointer.new(MAXIMUM_REPARSE_DATA_BUFFER_SIZE)
          parsed_size = FFI::Buffer.new(:long).write_long(0)
          if DeviceIoControl(handle, FSCTL_GET_REPARSE_POINT, nil, 0, reparse_buffer, MAXIMUM_REPARSE_DATA_BUFFER_SIZE, parsed_size, nil) == 0
            Chef::ReservedNames::Win32::Error.raise!
          end

          # Ensure it's a symbolic link
          reparse_buffer = REPARSE_DATA_BUFFER.new(reparse_buffer)
          if reparse_buffer[:ReparseTag] != IO_REPARSE_TAG_SYMLINK
            raise Errno::EACCES, "#{link_name} is not a symlink"
          end

          # Return the link destination (strip off \??\ at the beginning, which is a local filesystem thing)
          link_dest = reparse_buffer.reparse_buffer.substitute_name
          if link_dest =~ /^\\\?\?\\/
            link_dest = link_dest[4..-1]
          end
          link_dest
        end
      end

      # Gets the short form of a path (Administrator -> ADMINI~1)
      def self.get_short_path_name(path)
        path = path.to_wstring
        size = GetShortPathNameW(path, nil, 0)
        if size == 0
          Chef::ReservedNames::Win32::Error.raise!
        end
        result = FFI::MemoryPointer.new :char, (size+1)*2
        if GetShortPathNameW(path, result, size+1) == 0
          Chef::ReservedNames::Win32::Error.raise!
        end
        result.read_wstring(size)
      end

      # Gets the long form of a path (ADMINI~1 -> Administrator)
      def self.get_long_path_name(path)
        path = path.to_wstring
        size = GetLongPathNameW(path, nil, 0)
        if size == 0
          Chef::ReservedNames::Win32::Error.raise!
        end
        result = FFI::MemoryPointer.new :char, (size+1)*2
        if GetLongPathNameW(path, result, size+1) == 0
          Chef::ReservedNames::Win32::Error.raise!
        end
        result.read_wstring(size)
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
