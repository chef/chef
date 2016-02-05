#
# Author:: Matt Wrock (<matt@mattwrock.com>)
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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

require "chef/win32/file"

class Chef
  module ReservedNames::Win32
    class File

      class VersionInfo

        include Chef::ReservedNames::Win32::API::File

        def initialize(file_name)
          raise Errno::ENOENT, file_name unless ::File.exist?(file_name)
          @file_version_info = retrieve_file_version_info(file_name)
        end

        # defining method for each predefined version resource string
        # see https://msdn.microsoft.com/en-us/library/windows/desktop/ms647464(v=vs.85).aspx
        [
          :Comments,
          :CompanyName,
          :FileDescription,
          :FileVersion,
          :InternalName,
          :LegalCopyright,
          :LegalTrademarks,
          :OriginalFilename,
          :ProductName,
          :ProductVersion,
          :PrivateBuild,
          :SpecialBuild,
        ].each do |method|
          define_method method do
            begin
              get_version_info_string(method.to_s)
            rescue Chef::Exceptions::Win32APIError
              return nil
            end
          end
        end

        private

        def translation
          @translation ||= begin
            info_ptr = FFI::MemoryPointer.new(:pointer)
            unless VerQueryValueW(@file_version_info, "\\VarFileInfo\\Translation".to_wstring, info_ptr, FFI::MemoryPointer.new(:int))
              Chef::ReservedNames::Win32::Error.raise!
            end

            # there can potentially be multiple translations but most installers just have one
            # we use the first because we use this for the version strings which are language
            # agnostic. If/when we need other fields, we should we should add logic to find
            # the "best" translation
            trans = Translation.new(info_ptr.read_pointer)
            to_hex(trans[:w_lang]) + to_hex(trans[:w_code_page])
          end
        end

        def to_hex(integer)
          integer.to_s(16).rjust(4, "0")
        end

        def get_version_info_string(string_key)
          info_ptr = FFI::MemoryPointer.new(:pointer)
          size_ptr = FFI::MemoryPointer.new(:int)
          unless VerQueryValueW(@file_version_info, "\\StringFileInfo\\#{translation}\\#{string_key}".to_wstring, info_ptr, size_ptr)
            Chef::ReservedNames::Win32::Error.raise!
          end

          info_ptr.read_pointer.read_wstring(size_ptr.read_uint)
        end
      end
    end
  end
end
