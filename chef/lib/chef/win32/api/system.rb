#
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

require 'chef/win32/api'

class Chef
  module ReservedNames::Win32
    module API
      module System
        extend Chef::ReservedNames::Win32::API

        ###############################################
        # Win32 API Constants
        ###############################################

        # http://msdn.microsoft.com/en-us/library/ms724833(v=vs.85).aspx

        # Suite Masks
        # Microsoft BackOffice components are installed.
        VER_SUITE_BACKOFFICE = 0x00000004
        # Windows Server 2003, Web Edition is installed.
        VER_SUITE_BLADE = 0x00000400
        # Windows Server 2003, Compute Cluster Edition is installed.
        VER_SUITE_COMPUTE_SERVER = 0x00004000
        # Windows Server 2008 Datacenter, Windows Server 2003, Datacenter Edition, or Windows 2000 Datacenter Server is installed.
        VER_SUITE_DATACENTER = 0x00000080
        # Windows Server 2008 Enterprise, Windows Server 2003, Enterprise Edition, or Windows 2000 Advanced Server is installed. Refer to the Remarks section for more information about this bit flag.
        VER_SUITE_ENTERPRISE = 0x00000002
        # Windows XP Embedded is installed.
        VER_SUITE_EMBEDDEDNT = 0x00000040
        # Windows Vista Home Premium, Windows Vista Home Basic, or Windows XP Home Edition is installed.
        VER_SUITE_PERSONAL = 0x00000200
        # Remote Desktop is supported, but only one interactive session is supported. This value is set unless the system is running in application server mode.
        VER_SUITE_SINGLEUSERTS = 0x00000100
        # Microsoft Small Business Server was once installed on the system, but may have been upgraded to another version of Windows. Refer to the Remarks section for more information about this bit flag.
        VER_SUITE_SMALLBUSINESS = 0x00000001
        # Microsoft Small Business Server is installed with the restrictive client license in force. Refer to the Remarks section for more information about this bit flag.
        VER_SUITE_SMALLBUSINESS_RESTRICTED = 0x00000020
        # Windows Storage Server 2003 R2 or Windows Storage Server 2003is installed.
        VER_SUITE_STORAGE_SERVER = 0x00002000
        # Terminal Services is installed. This value is always set.
        # If VER_SUITE_TERMINAL is set but VER_SUITE_SINGLEUSERTS is not set, the system is running in application server mode.
        VER_SUITE_TERMINAL = 0x00000010
        # Windows Home Server is installed.
        VER_SUITE_WH_SERVER = 0x00008000

        # Product Type
        # The system is a domain controller and the operating system is Windows Server 2008 R2, Windows Server 2008, Windows Server 2003, or Windows 2000 Server.
        VER_NT_DOMAIN_CONTROLLER = 0x0000002
        # The operating system is Windows Server 2008 R2, Windows Server 2008, Windows Server 2003, or Windows 2000 Server.
        # Note that a server that is also a domain controller is reported as VER_NT_DOMAIN_CONTROLLER, not VER_NT_SERVER.
        VER_NT_SERVER = 0x0000003
        # The operating system is Windows 7, Windows Vista, Windows XP Professional, Windows XP Home Edition, or Windows 2000 Professional.
        VER_NT_WORKSTATION = 0x0000001

        # Product Info
        # http://msdn.microsoft.com/en-us/library/ms724358(v=vs.85).aspx
        PRODUCT_BUSINESS = 0x00000006 # Business
        PRODUCT_BUSINESS_N = 0x00000010 # Business N
        PRODUCT_CLUSTER_SERVER = 0x00000012 # HPC Edition
        PRODUCT_DATACENTER_SERVER = 0x00000008 # Server Datacenter (full installation)
        PRODUCT_DATACENTER_SERVER_CORE = 0x0000000C # Server Datacenter (core installation)
        PRODUCT_DATACENTER_SERVER_CORE_V = 0x00000027 # Server Datacenter without Hyper-V (core installation)
        PRODUCT_DATACENTER_SERVER_V = 0x00000025 # Server Datacenter without Hyper-V (full installation)
        PRODUCT_ENTERPRISE = 0x00000004 # Enterprise
        PRODUCT_ENTERPRISE_E = 0x00000046 # Not supported
        PRODUCT_ENTERPRISE_N = 0x0000001B # Enterprise N
        PRODUCT_ENTERPRISE_SERVER = 0x0000000A # Server Enterprise (full installation)
        PRODUCT_ENTERPRISE_SERVER_CORE = 0x0000000E # Server Enterprise (core installation)
        PRODUCT_ENTERPRISE_SERVER_CORE_V = 0x00000029 # Server Enterprise without Hyper-V (core installation)
        PRODUCT_ENTERPRISE_SERVER_IA64 = 0x0000000F # Server Enterprise for Itanium-based Systems
        PRODUCT_ENTERPRISE_SERVER_V = 0x00000026 # Server Enterprise without Hyper-V (full installation)
        PRODUCT_HOME_BASIC = 0x00000002 # Home Basic
        PRODUCT_HOME_BASIC_E = 0x00000043 # Not supported
        PRODUCT_HOME_BASIC_N = 0x00000005 # Home Basic N
        PRODUCT_HOME_PREMIUM = 0x00000003 # Home Premium
        PRODUCT_HOME_PREMIUM_E = 0x00000044 # Not supported
        PRODUCT_HOME_PREMIUM_N = 0x0000001A # Home Premium N
        PRODUCT_HYPERV = 0x0000002A # Microsoft Hyper-V Server
        PRODUCT_MEDIUMBUSINESS_SERVER_MANAGEMENT = 0x0000001E # Windows Essential Business Server Management Server
        PRODUCT_MEDIUMBUSINESS_SERVER_MESSAGING = 0x00000020 # Windows Essential Business Server Messaging Server
        PRODUCT_MEDIUMBUSINESS_SERVER_SECURITY = 0x0000001F # Windows Essential Business Server Security Server
        PRODUCT_PROFESSIONAL = 0x00000030 # Professional
        PRODUCT_PROFESSIONAL_E = 0x00000045 # Not supported
        PRODUCT_PROFESSIONAL_N = 0x00000031 # Professional N
        PRODUCT_SERVER_FOR_SMALLBUSINESS = 0x00000018 # Windows Server 2008 for Windows Essential Server Solutions
        PRODUCT_SERVER_FOR_SMALLBUSINESS_V = 0x00000023 # Windows Server 2008 without Hyper-V for Windows Essential Server Solutions
        PRODUCT_SERVER_FOUNDATION = 0x00000021 # Server Foundation
        PRODUCT_HOME_PREMIUM_SERVER = 0x00000022 # Windows Home Server 2011
        PRODUCT_SB_SOLUTION_SERVER = 0x00000032 # Windows Small Business Server 2011 Essentials
        PRODUCT_HOME_SERVER = 0x00000013 # Windows Storage Server 2008 R2 Essentials
        PRODUCT_SMALLBUSINESS_SERVER = 0x00000009 # Windows Small Business Server
        PRODUCT_SOLUTION_EMBEDDEDSERVER = 0x00000038 # Windows MultiPoint Server
        PRODUCT_STANDARD_SERVER = 0x00000007 # Server Standard (full installation)
        PRODUCT_STANDARD_SERVER_CORE = 0x0000000D # Server Standard (core installation)
        PRODUCT_STANDARD_SERVER_CORE_V = 0x00000028 # Server Standard without Hyper-V (core installation)
        PRODUCT_STANDARD_SERVER_V = 0x00000024 # Server Standard without Hyper-V (full installation)
        PRODUCT_STARTER = 0x0000000B # Starter
        PRODUCT_STARTER_E = 0x00000042 # Not supported
        PRODUCT_STARTER_N = 0x0000002F # Starter N
        PRODUCT_STORAGE_ENTERPRISE_SERVER = 0x00000017 # Storage Server Enterprise
        PRODUCT_STORAGE_EXPRESS_SERVER = 0x00000014 # Storage Server Express
        PRODUCT_STORAGE_STANDARD_SERVER = 0x00000015 # Storage Server Standard
        PRODUCT_STORAGE_WORKGROUP_SERVER = 0x00000016 # Storage Server Workgroup
        PRODUCT_UNDEFINED = 0x00000000 # An unknown product
        PRODUCT_ULTIMATE = 0x00000001 # Ultimate
        PRODUCT_ULTIMATE_E = 0x00000047 # Not supported
        PRODUCT_ULTIMATE_N = 0x0000001C # Ultimate N
        PRODUCT_WEB_SERVER = 0x00000011 # Web Server (full installation)
        PRODUCT_WEB_SERVER_CORE = 0x0000001D # Web Server (core installation)

        # GetSystemMetrics
        # The build number if the system is Windows Server 2003 R2; otherwise, 0.
        SM_SERVERR2 = 89

        ###############################################
        # Win32 API Bindings
        ###############################################

        ffi_lib 'kernel32', 'user32'

        class OSVERSIONINFOEX < FFI::Struct
          layout :dw_os_version_info_size, :DWORD,
            :dw_major_version, :DWORD,
            :dw_minor_version, :DWORD,
            :dw_build_number, :DWORD,
            :dw_platform_id, :DWORD,
            :sz_csd_version, [:BYTE, 256],
            :w_service_pack_major, :WORD,
            :w_service_pack_minor, :WORD,
            :w_suite_mask, :WORD,
            :w_product_type, :BYTE,
            :w_reserved, :BYTE
        end

=begin
BOOL WINAPI CloseHandle(
  __in  HANDLE hObject
);
=end
        attach_function :CloseHandle, [ :HANDLE ], :BOOL

=begin
DWORD WINAPI GetVersion(void);
=end
        attach_function :GetVersion, [], :DWORD

=begin
BOOL WINAPI GetVersionEx(
  __inout  LPOSVERSIONINFO lpVersionInfo
);
=end
        attach_function :GetVersionExW, [:pointer], :BOOL
        attach_function :GetVersionExA, [:pointer], :BOOL

=begin
BOOL WINAPI GetProductInfo(
  __in   DWORD dwOSMajorVersion,
  __in   DWORD dwOSMinorVersion,
  __in   DWORD dwSpMajorVersion,
  __in   DWORD dwSpMinorVersion,
  __out  PDWORD pdwReturnedProductType
);
=end
        attach_function :GetProductInfo, [:DWORD, :DWORD, :DWORD, :DWORD, :PDWORD], :BOOL

=begin
int WINAPI GetSystemMetrics(
  __in  int nIndex
);
=end
        attach_function :GetSystemMetrics, [:int], :int

      end
    end
  end
end
