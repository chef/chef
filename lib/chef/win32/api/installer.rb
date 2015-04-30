#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

require 'chef/exceptions'
require 'chef/win32/api'
require 'chef/win32/error'
require 'pathname'

class Chef
  module ReservedNames::Win32
    module API
      module Installer
        extend Chef::ReservedNames::Win32
        extend Chef::ReservedNames::Win32::API

        ###############################################
        # Win32 API Constants
        ###############################################


        ###############################################
        # Win32 API Bindings
        ###############################################

        ffi_lib 'msi'

=begin
UINT MsiOpenPackage(
  _In_   LPCTSTR szPackagePath,
  _Out_  MSIHANDLE *hProduct
);
=end
        safe_attach_function :msi_open_package, :MsiOpenPackageExA, [ :string, :int, :pointer ], :int

=begin
UINT MsiGetProductProperty(
  _In_     MSIHANDLE hProduct,
  _In_     LPCTSTR szProperty,
  _Out_    LPTSTR lpValueBuf,
  _Inout_  DWORD *pcchValueBuf
);
=end
        safe_attach_function :msi_get_product_property, :MsiGetProductPropertyA, [ :pointer, :pointer, :pointer, :pointer ], :int

=begin
UINT MsiGetProductInfo(
  _In_     LPCTSTR szProduct,
  _In_     LPCTSTR szProperty,
  _Out_    LPTSTR lpValueBuf,
  _Inout_  DWORD *pcchValueBuf
);
=end
        safe_attach_function :msi_get_product_info, :MsiGetProductInfoA, [ :pointer, :pointer, :pointer, :pointer ], :int

=begin
UINT MsiCloseHandle(
  _In_  MSIHANDLE hAny
);
=end
        safe_attach_function :msi_close_handle, :MsiCloseHandle, [ :pointer ], :int

        ###############################################
        # Helpers
        ###############################################

        # Opens a Microsoft Installer (MSI) file from an absolute path and returns the specified property
        def get_product_property(package_path, property_name)
          pkg_ptr = open_package(package_path)

          buffer = 0.chr
          buffer_length = FFI::Buffer.new(:long).write_long(0)

          # Fetch the length of the property
          status = msi_get_product_property(pkg_ptr.read_pointer, property_name, buffer, buffer_length)

          # We expect error ERROR_MORE_DATA (234) here because we passed a buffer length of 0
          if status != 234
            msg = "msi_get_product_property: returned unknown error #{status} when retrieving #{property_name}: "
            msg << Chef::ReservedNames::Win32::Error.format_message(status)
            raise Chef::Exceptions::Package, msg
          end
         
          buffer_length = FFI::Buffer.new(:long).write_long(buffer_length.read_long + 1)
          buffer = 0.chr * buffer_length.read_long

          # Fetch the property
          status = msi_get_product_property(pkg_ptr.read_pointer, property_name, buffer, buffer_length)

          if status != 0
            msg = "msi_get_product_property: returned unknown error #{status} when retrieving #{property_name}: "
            msg << Chef::ReservedNames::Win32::Error.format_message(status)
            raise Chef::Exceptions::Package, msg
          end

          msi_close_handle(pkg_ptr.read_pointer)
          return buffer.chomp(0.chr)
        end

        # Opens a Microsoft Installer (MSI) file from an absolute path and returns a pointer to a handle
        # Remember to close the handle with msi_close_handle()
        def open_package(package_path)
          # MsiOpenPackage expects a perfect absolute Windows path to the MSI 
          raise ArgumentError, "Provided path '#{package_path}' must be an absolute path" unless Pathname.new(package_path).absolute?

          pkg_ptr = FFI::MemoryPointer.new(:pointer, 4)
          status = msi_open_package(package_path, 1, pkg_ptr)
          case status
          when 0 
            # success
          else
            raise Chef::Exceptions::Package, "msi_open_package: unexpected status #{status}: #{Chef::ReservedNames::Win32::Error.format_message(status)}"
          end
          return pkg_ptr        
        end

        # All installed product_codes should have a VersionString
        # Returns a version if installed, nil if not installed
        def get_installed_version(product_code)
          version = 0.chr
          version_length = FFI::Buffer.new(:long).write_long(0)
         
          status = msi_get_product_info(product_code, "VersionString", version, version_length)
          
          return nil if status == 1605 # ERROR_UNKNOWN_PRODUCT (0x645)
         
          # We expect error ERROR_MORE_DATA (234) here because we passed a buffer length of 0
          if status != 234
            msg = "msi_get_product_info: product code '#{product_code}' returned unknown error #{status} when retrieving VersionString: "
            msg << Chef::ReservedNames::Win32::Error.format_message(status)
            raise Chef::Exceptions::Package, msg
          end

          # We could fetch the product version now that we know the variable length, but we don't need it here.

          version_length = FFI::Buffer.new(:long).write_long(version_length.read_long + 1)
          version = 0.chr * version_length.read_long
           
          status = msi_get_product_info(product_code, "VersionString", version, version_length)
           
          if status != 0
            msg = "msi_get_product_info: product code '#{product_code}' returned unknown error #{status} when retrieving VersionString: "
            msg << Chef::ReservedNames::Win32::Error.format_message(status)
            raise Chef::Exceptions::Package, msg
          end

          version.chomp(0.chr)
        end
      end
    end
  end
end
