#
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require "ffi" unless defined?(FFI)
require_relative "../reserved_names"
require_relative "../exceptions"

class Chef
  module ReservedNames::Win32
    module API

      # Attempts to use FFI's attach_function method to link a native Win32
      # function into the calling module.  If this fails a dummy method is
      # defined which when called, raises a helpful exception to the end-user.
      def safe_attach_function(win32_func, *args)
        attach_function(win32_func.to_sym, *args)
      rescue FFI::NotFoundError
        define_method(win32_func.to_sym) do |*margs|
          raise Chef::Exceptions::Win32APIFunctionNotImplemented, "This version of Windows does not implement the Win32 function [#{win32_func}]."
        end
      end

      # put shared stuff (like constants) for all raw Win32 API calls
      def self.extended(host)
        host.extend FFI::Library
        host.extend Macros

        host.ffi_convention :stdcall

        win64 = ENV["PROCESSOR_ARCHITECTURE"] == "AMD64"

        # Windows-specific type defs (ms-help://MS.MSDNQTR.v90.en/winprog/winprog/windows_data_types.htm):
        host.typedef :ushort,  :ATOM # Atom ~= Symbol: Atom table stores strings and corresponding identifiers. Application
        # places a string in an atom table and receives a 16-bit integer, called an atom, that
        # can be used to access the string. Placed string is called an atom name.
        # See: http://msdn.microsoft.com/en-us/library/ms648708%28VS.85%29.aspx
        host.typedef :bool,    :BOOL
        host.typedef :bool,    :BOOLEAN
        host.typedef :uchar,   :BYTE # Byte (8 bits). Declared as unsigned char
        # CALLBACK:  K,       # Win32.API gem-specific ?? MSDN: #define CALLBACK __stdcall
        host.typedef :char,    :CHAR # 8-bit Windows (ANSI) character. See http://msdn.microsoft.com/en-us/library/dd183415%28VS.85%29.aspx
        host.typedef :uint32,  :COLORREF # Red, green, blue (RGB) color value (32 bits). See COLORREF for more info.
        host.typedef :uint32,  :DWORD # 32-bit unsigned integer. The range is 0 through 4,294,967,295 decimal.
        host.typedef :uint64,  :DWORDLONG # 64-bit unsigned integer. The range is 0 through 18,446,744,073,709,551,615 decimal.
        host.typedef :ulong,   :DWORD_PTR # Unsigned long type for pointer precision. Use when casting a pointer to a long type
        # to perform pointer arithmetic. (Also commonly used for general 32-bit parameters that have
        # been extended to 64 bits in 64-bit Windows.)  BaseTsd.h: #host.typedef ULONG_PTR DWORD_PTR;
        host.typedef :uint32,  :DWORD32
        host.typedef :uint64,  :DWORD64
        host.typedef :int,     :HALF_PTR # Half the size of a pointer. Use within a structure that contains a pointer and two small fields.
        # BaseTsd.h: #ifdef (_WIN64) host.typedef int HALF_PTR; #else host.typedef short HALF_PTR;
        host.typedef :ulong,   :HACCEL # (L) Handle to an accelerator table. WinDef.h: #host.typedef HANDLE HACCEL;
        # See http://msdn.microsoft.com/en-us/library/ms645526%28VS.85%29.aspx
        host.typedef :size_t, :HANDLE # (L) Handle to an object. WinNT.h: #host.typedef PVOID HANDLE;
        # todo: Platform-dependent! Need to change to :uint64 for Win64
        host.typedef :ulong,   :HBITMAP # (L) Handle to a bitmap: http://msdn.microsoft.com/en-us/library/dd183377%28VS.85%29.aspx
        host.typedef :ulong,   :HBRUSH # (L) Handle to a brush. http://msdn.microsoft.com/en-us/library/dd183394%28VS.85%29.aspx
        host.typedef :ulong,   :HCOLORSPACE # (L) Handle to a color space. http://msdn.microsoft.com/en-us/library/ms536546%28VS.85%29.aspx
        host.typedef :ulong,   :HCURSOR # (L) Handle to a cursor. http://msdn.microsoft.com/en-us/library/ms646970%28VS.85%29.aspx
        host.typedef :ulong,   :HCONV # (L) Handle to a dynamic data exchange (DDE) conversation.
        host.typedef :ulong,   :HCONVLIST # (L) Handle to a DDE conversation list. HANDLE - L ?
        host.typedef :ulong,   :HDDEDATA # (L) Handle to DDE data (structure?)
        host.typedef :ulong,   :HDC # (L) Handle to a device context (DC). http://msdn.microsoft.com/en-us/library/dd183560%28VS.85%29.aspx
        host.typedef :ulong,   :HDESK # (L) Handle to a desktop. http://msdn.microsoft.com/en-us/library/ms682573%28VS.85%29.aspx
        host.typedef :ulong,   :HDROP # (L) Handle to an internal drop structure.
        host.typedef :ulong,   :HDWP # (L) Handle to a deferred window position structure.
        host.typedef :ulong,   :HENHMETAFILE # (L) Handle to an enhanced metafile. http://msdn.microsoft.com/en-us/library/dd145051%28VS.85%29.aspx
        host.typedef :uint,    :HFILE # (I) Special file handle to a file opened by OpenFile, not CreateFile.
        # WinDef.h: #host.typedef int HFILE;
        host.typedef :ulong,   :HFONT # (L) Handle to a font. http://msdn.microsoft.com/en-us/library/dd162470%28VS.85%29.aspx
        host.typedef :ulong,   :HGDIOBJ # (L) Handle to a GDI object.
        host.typedef :ulong,   :HGLOBAL # (L) Handle to a global memory block.
        host.typedef :ulong,   :HHOOK # (L) Handle to a hook. http://msdn.microsoft.com/en-us/library/ms632589%28VS.85%29.aspx
        host.typedef :ulong,   :HICON # (L) Handle to an icon. http://msdn.microsoft.com/en-us/library/ms646973%28VS.85%29.aspx
        host.typedef :ulong,   :HINSTANCE # (L) Handle to an instance. This is the base address of the module in memory.
        # HMODULE and HINSTANCE are the same today, but were different in 16-bit Windows.
        host.typedef :ulong,   :HKEY # (L) Handle to a registry key.
        host.typedef :ulong,   :HKL # (L) Input locale identifier.
        host.typedef :ulong,   :HLOCAL # (L) Handle to a local memory block.
        host.typedef :ulong,   :HMENU # (L) Handle to a menu. http://msdn.microsoft.com/en-us/library/ms646977%28VS.85%29.aspx
        host.typedef :ulong,   :HMETAFILE # (L) Handle to a metafile. http://msdn.microsoft.com/en-us/library/dd145051%28VS.85%29.aspx
        host.typedef :ulong,   :HMODULE # (L) Handle to an instance. Same as HINSTANCE today, but was different in 16-bit Windows.
        host.typedef :ulong,   :HMONITOR # (L) Handle to a display monitor. WinDef.h: if(WINVER >= 0x0500) host.typedef HANDLE HMONITOR;
        host.typedef :ulong,   :HPALETTE # (L) Handle to a palette.
        host.typedef :ulong,   :HPEN # (L) Handle to a pen. http://msdn.microsoft.com/en-us/library/dd162786%28VS.85%29.aspx
        host.typedef :long,    :HRESULT # Return code used by COM interfaces. For more info, Structure of the COM Error Codes.
        # To test an HRESULT value, use the FAILED and SUCCEEDED macros.
        host.typedef :ulong,   :HRGN # (L) Handle to a region. http://msdn.microsoft.com/en-us/library/dd162913%28VS.85%29.aspx
        host.typedef :ulong,   :HRSRC # (L) Handle to a resource.
        host.typedef :ulong,   :HSZ # (L) Handle to a DDE string.
        host.typedef :ulong,   :HWINSTA # (L) Handle to a window station. http://msdn.microsoft.com/en-us/library/ms687096%28VS.85%29.aspx
        host.typedef :ulong,   :HWND # (L) Handle to a window. http://msdn.microsoft.com/en-us/library/ms632595%28VS.85%29.aspx
        host.typedef :int,     :INT # 32-bit signed integer. The range is -2147483648 through 2147483647 decimal.
        host.typedef :int,     :INT_PTR # Signed integer type for pointer precision. Use when casting a pointer to an integer
        # to perform pointer arithmetic. BaseTsd.h:
        # if defined(_WIN64) host.typedef __int64 INT_PTR; #else host.typedef int INT_PTR;
        host.typedef :int32,   :INT32 # 32-bit signed integer. The range is -2,147,483,648 through +...647 decimal.
        host.typedef :int64,   :INT64 # 64-bit signed integer. The range is –9,223,372,036,854,775,808 through +...807
        host.typedef :ushort,  :LANGID # Language identifier. For more information, see Locales. WinNT.h: #host.typedef WORD LANGID;
        # See http://msdn.microsoft.com/en-us/library/dd318716%28VS.85%29.aspx
        host.typedef :uint32,  :LCID # Locale identifier. For more information, see Locales.
        host.typedef :uint32,  :LCTYPE # Locale information type. For a list, see Locale Information Constants.
        host.typedef :uint32,  :LGRPID # Language group identifier. For a list, see EnumLanguageGroupLocales.
        host.typedef :pointer, :LMSTR # Pointer to null terminated string of unicode characters
        host.typedef :long,    :LONG # 32-bit signed integer. The range is -2,147,483,648 through +...647 decimal.
        host.typedef :int32,   :LONG32 # 32-bit signed integer. The range is -2,147,483,648 through +...647 decimal.
        host.typedef :int64,   :LONG64 # 64-bit signed integer. The range is –9,223,372,036,854,775,808 through +...807
        host.typedef :int64,   :LONGLONG # 64-bit signed integer. The range is –9,223,372,036,854,775,808 through +...807
        # perform pointer arithmetic. BaseTsd.h:
        # if defined(_WIN64) host.typedef __int64 LONG_PTR; #else host.typedef long LONG_PTR;
        if win64
          host.typedef :int64,    :LONG_PTR # Signed long type for pointer precision. Use when casting a pointer to a long to
          host.typedef :int64,    :LPARAM # Message parameter. WinDef.h as follows: #host.typedef LONG_PTR LPARAM;
        else
          host.typedef :long,    :LONG_PTR # Signed long type for pointer precision. Use when casting a pointer to a long to
          host.typedef :long,    :LPARAM # Message parameter. WinDef.h as follows: #host.typedef LONG_PTR LPARAM;
        end
        host.typedef :pointer, :LPBOOL # Pointer to a BOOL. WinDef.h as follows: #host.typedef BOOL far *LPBOOL;
        host.typedef :pointer, :LPBYTE # Pointer to a BYTE. WinDef.h as follows: #host.typedef BYTE far *LPBYTE;
        host.typedef :pointer, :LPCOLORREF # Pointer to a COLORREF value. WinDef.h as follows: #host.typedef DWORD *LPCOLORREF;
        host.typedef :pointer, :LPCSTR # Pointer to a constant null-terminated string of 8-bit Windows (ANSI) characters.
        # See Character Sets Used By Fonts. http://msdn.microsoft.com/en-us/library/dd183415%28VS.85%29.aspx
        host.typedef :pointer, :LPCTSTR # An LPCWSTR if UNICODE is defined, an LPCSTR otherwise.
        host.typedef :pointer, :LPCVOID # Pointer to a constant of any type. WinDef.h as follows: host.typedef CONST void *LPCVOID;
        host.typedef :pointer, :LPCWSTR # Pointer to a constant null-terminated string of 16-bit Unicode characters.
        host.typedef :pointer, :LPDWORD # Pointer to a DWORD. WinDef.h as follows: host.typedef DWORD *LPDWORD;
        host.typedef :pointer, :LPHANDLE # Pointer to a HANDLE. WinDef.h as follows: host.typedef HANDLE *LPHANDLE;
        host.typedef :pointer, :LPINT # Pointer to an INT.
        host.typedef :pointer, :LPLONG # Pointer to an LONG.
        host.typedef :pointer, :LPSECURITY_ATTRIBUTES # Pointer to SECURITY_ATTRIBUTES struct
        host.typedef :pointer, :LPSTR # Pointer to a null-terminated string of 8-bit Windows (ANSI) characters.
        host.typedef :pointer, :LPTSTR # An LPWSTR if UNICODE is defined, an LPSTR otherwise.
        host.typedef :pointer, :LPVOID # Pointer to any type.
        host.typedef :pointer, :LPWORD # Pointer to a WORD.
        host.typedef :pointer, :LPWSTR # Pointer to a null-terminated string of 16-bit Unicode characters.
        host.typedef :long,    :LRESULT # Signed result of message processing. WinDef.h: host.typedef LONG_PTR LRESULT;
        host.typedef :pointer, :LPWIN32_FIND_DATA # Pointer to WIN32_FIND_DATA struct
        host.typedef :pointer, :LPBY_HANDLE_FILE_INFORMATION # Point to a BY_HANDLE_FILE_INFORMATION struct
        host.typedef :pointer, :LSA_HANDLE # A handle to a Policy object
        host.typedef :ulong,   :NTSTATUS # An NTSTATUS code returned by an LSA function call.
        host.typedef :pointer, :PBOOL # Pointer to a BOOL.
        host.typedef :pointer, :PBOOLEAN # Pointer to a BOOL.
        host.typedef :pointer, :PBYTE # Pointer to a BYTE.
        host.typedef :pointer, :PCHAR # Pointer to a CHAR.
        host.typedef :pointer, :PCSTR # Pointer to a constant null-terminated string of 8-bit Windows (ANSI) characters.
        host.typedef :pointer, :PCTSTR # A PCWSTR if UNICODE is defined, a PCSTR otherwise.
        host.typedef :pointer, :PCWSTR # Pointer to a constant null-terminated string of 16-bit Unicode characters.
        host.typedef :pointer, :PDWORD # Pointer to a DWORD.
        host.typedef :pointer, :PDWORDLONG # Pointer to a DWORDLONG.
        host.typedef :pointer, :PDWORD_PTR # Pointer to a DWORD_PTR.
        host.typedef :pointer, :PDWORD32 # Pointer to a DWORD32.
        host.typedef :pointer, :PDWORD64 # Pointer to a DWORD64.
        host.typedef :pointer, :PFLOAT # Pointer to a FLOAT.
        host.typedef :pointer, :PGENERICMAPPING # Pointer to GENERIC_MAPPING
        host.typedef :pointer, :PHALF_PTR # Pointer to a HALF_PTR.
        host.typedef :pointer, :PHANDLE # Pointer to a HANDLE.
        host.typedef :pointer, :PHKEY # Pointer to an HKEY.
        host.typedef :pointer, :PINT # Pointer to an INT.
        host.typedef :pointer, :PINT_PTR # Pointer to an INT_PTR.
        host.typedef :pointer, :PINT32 # Pointer to an INT32.
        host.typedef :pointer, :PINT64 # Pointer to an INT64.
        host.typedef :pointer, :PLCID # Pointer to an LCID.
        host.typedef :pointer, :PLONG # Pointer to a LONG.
        host.typedef :pointer, :PLONGLONG # Pointer to a LONGLONG.
        host.typedef :pointer, :PLONG_PTR # Pointer to a LONG_PTR.
        host.typedef :pointer, :PLONG32 # Pointer to a LONG32.
        host.typedef :pointer, :PLONG64 # Pointer to a LONG64.
        host.typedef :pointer, :PLSA_HANDLE # Pointer to an LSA_HANDLE
        host.typedef :pointer, :PLSA_OBJECT_ATTRIBUTES # Pointer to an LSA_OBJECT_ATTRIBUTES
        host.typedef :pointer, :PLSA_UNICODE_STRING # Pointer to LSA_UNICODE_STRING
        host.typedef :pointer, :PLUID # Pointer to a LUID.
        host.typedef :pointer, :POINTER_32 # 32-bit pointer. On a 32-bit system, this is a native pointer. On a 64-bit system, this is a truncated 64-bit pointer.
        host.typedef :pointer, :POINTER_64 # 64-bit pointer. On a 64-bit system, this is a native pointer. On a 32-bit system, this is a sign-extended 32-bit pointer.
        host.typedef :pointer, :POINTER_SIGNED # A signed pointer.
        host.typedef :pointer, :POINTER_UNSIGNED # An unsigned pointer.
        host.typedef :pointer, :PSHORT # Pointer to a SHORT.
        host.typedef :pointer, :PSID # Pointer to an account SID
        host.typedef :pointer, :PSIZE_T # Pointer to a SIZE_T.
        host.typedef :pointer, :PSSIZE_T # Pointer to a SSIZE_T.
        host.typedef :pointer, :PSTR # Pointer to a null-terminated string of 8-bit Windows (ANSI) characters. For more information, see Character Sets Used By Fonts.
        host.typedef :pointer, :PTBYTE # Pointer to a TBYTE.
        host.typedef :pointer, :PTCHAR # Pointer to a TCHAR.
        host.typedef :pointer, :PCRYPTPROTECT_PROMPTSTRUCT # Pointer to a CRYPTOPROTECT_PROMPTSTRUCT.
        host.typedef :pointer, :PDATA_BLOB # Pointer to a DATA_BLOB.
        host.typedef :pointer, :PTSTR # A PWSTR if UNICODE is defined, a PSTR otherwise.
        host.typedef :pointer, :PUCHAR # Pointer to a UCHAR.
        host.typedef :pointer, :PUHALF_PTR # Pointer to a UHALF_PTR.
        host.typedef :pointer, :PUINT # Pointer to a UINT.
        host.typedef :pointer, :PUINT_PTR # Pointer to a UINT_PTR.
        host.typedef :pointer, :PUINT32 # Pointer to a UINT32.
        host.typedef :pointer, :PUINT64 # Pointer to a UINT64.
        host.typedef :pointer, :PULONG # Pointer to a ULONG.
        host.typedef :pointer, :PULONGLONG # Pointer to a ULONGLONG.
        host.typedef :pointer, :PULONG_PTR # Pointer to a ULONG_PTR.
        host.typedef :pointer, :PULONG32 # Pointer to a ULONG32.
        host.typedef :pointer, :PULONG64 # Pointer to a ULONG64.
        host.typedef :pointer, :PUSHORT # Pointer to a USHORT.
        host.typedef :pointer, :PVOID # Pointer to any type.
        host.typedef :pointer, :PWCHAR # Pointer to a WCHAR.
        host.typedef :pointer, :PWORD # Pointer to a WORD.
        host.typedef :pointer, :PWSTR # Pointer to a null- terminated string of 16-bit Unicode characters.
        # For more information, see Character Sets Used By Fonts.
        host.typedef :ulong,   :SC_HANDLE # (L) Handle to a service control manager database.
        # See SCM Handles http://msdn.microsoft.com/en-us/library/ms685104%28VS.85%29.aspx
        host.typedef :pointer, :SC_LOCK # Lock to a service control manager database. For more information, see SCM Handles.
        host.typedef :ulong,   :SERVICE_STATUS_HANDLE # (L) Handle to a service status value. See SCM Handles.
        host.typedef :short,   :SHORT # A 16-bit integer. The range is –32768 through 32767 decimal.
        host.typedef :ulong,   :SIZE_T #  The maximum number of bytes to which a pointer can point. Use for a count that must span the full range of a pointer.
        host.typedef :long,    :SSIZE_T # Signed SIZE_T.
        host.typedef :char,    :TBYTE # A WCHAR if UNICODE is defined, a CHAR otherwise.TCHAR:
        # http://msdn.microsoft.com/en-us/library/c426s321%28VS.80%29.aspx
        host.typedef :char,    :TCHAR # A WCHAR if UNICODE is defined, a CHAR otherwise.TCHAR:
        host.typedef :uchar,   :UCHAR # Unsigned CHAR (8 bit)
        host.typedef :uint,    :UHALF_PTR # Unsigned HALF_PTR. Use within a structure that contains a pointer and two small fields.
        host.typedef :uint,    :UINT # Unsigned INT. The range is 0 through 4294967295 decimal.
        host.typedef :uint,    :UINT_PTR # Unsigned INT_PTR.
        host.typedef :uint32,  :UINT32 # Unsigned INT32. The range is 0 through 4294967295 decimal.
        host.typedef :uint64,  :UINT64 # Unsigned INT64. The range is 0 through 18446744073709551615 decimal.
        host.typedef :ulong,   :ULONG # Unsigned LONG. The range is 0 through 4294967295 decimal.
        host.typedef :ulong_long, :ULONGLONG # 64-bit unsigned integer. The range is 0 through 18446744073709551615 decimal.
        host.typedef :ulong,   :ULONG_PTR # Unsigned LONG_PTR.
        host.typedef :uint32,  :ULONG32 # Unsigned INT32. The range is 0 through 4294967295 decimal.
        host.typedef :uint64,  :ULONG64 # Unsigned LONG64. The range is 0 through 18446744073709551615 decimal.
        host.typedef :pointer, :UNICODE_STRING # Pointer to some string structure??
        host.typedef :ushort,  :USHORT # Unsigned SHORT. The range is 0 through 65535 decimal.
        host.typedef :ulong_long, :USN # Update sequence number (USN).
        host.typedef :ushort,  :WCHAR # 16-bit Unicode character. For more information, see Character Sets Used By Fonts.
        # In WinNT.h: host.typedef wchar_t WCHAR;
        # WINAPI: K,      # Calling convention for system functions. WinDef.h: define WINAPI __stdcall
        host.typedef :ushort,  :WORD # 16-bit unsigned integer. The range is 0 through 65535 decimal.
        host.typedef :uint,    :WPARAM # Message parameter. WinDef.h as follows: host.typedef UINT_PTR WPARAM;
      end

      module Macros

        ###############################################
        # winbase.h
        ###############################################

        def LocalDiscard(pointer)
          LocalReAlloc(pointer, 0, LMEM_MOVEABLE)
        end

        ###############################################
        # windef.h
        ###############################################

        # Creates a WORD value by concatenating the specified values.
        #
        # http://msdn.microsoft.com/en-us/library/windows/desktop/ms632663(v=VS.85).aspx
        def MAKEWORD(low, high)
          ((low & 0xff) | (high & 0xff)) << 8
        end

        # Creates a LONG value by concatenating the specified values.
        #
        # http://msdn.microsoft.com/en-us/library/windows/desktop/ms632660(v=vs.85).aspx
        def MAKELONG(low, high)
          ((low & 0xffff) | (high & 0xffff)) << 16
        end

        # Retrieves the low-order word from the specified value.
        #
        # http://msdn.microsoft.com/en-us/library/windows/desktop/ms632659(v=VS.85).aspx
        def LOWORD(l)
          l & 0xffff
        end

        # Retrieves the high-order word from the specified 32-bit value.
        #
        # http://msdn.microsoft.com/en-us/library/windows/desktop/ms632657(v=VS.85).aspx
        def HIWORD(l)
          l >> 16
        end

        # Retrieves the low-order byte from the specified value.
        #
        # http://msdn.microsoft.com/en-us/library/windows/desktop/ms632658(v=VS.85).aspx
        def LOBYTE(w)
          w & 0xff
        end

        # Retrieves the high-order byte from the given 16-bit value.
        #
        # http://msdn.microsoft.com/en-us/library/windows/desktop/ms632656(v=VS.85).aspx
        def HIBYTE(w)
          w >> 8
        end

        ###############################################
        # winerror.h
        ###############################################

        def IS_ERROR(status)
          status >> 31 == 1
        end

        def MAKE_HRESULT(sev, fac, code)
          sev << 31 | fac << 16 | code
        end

        def MAKE_SCODE(sev, fac, code)
          sev << 31 | fac << 16 | code
        end

        def HRESULT_CODE(hr)
          hr & 0xFFFF
        end

        def HRESULT_FACILITY(hr)
          (hr >> 16) & 0x1fff
        end

        def HRESULT_FROM_NT(x)
          x | 0x10000000 # FACILITY_NT_BIT
        end

        def HRESULT_FROM_WIN32(x)
          if x <= 0
            x
          else
            (x & 0x0000FFFF) | (7 << 16) | 0x80000000
          end
        end

        def HRESULT_SEVERITY(hr)
          (hr >> 31) & 0x1
        end

        def FAILED(status)
          status < 0
        end

        def SUCCEEDED(status)
          status >= 0
        end
      end

      # Represents a 64-bit unsigned integer value.
      #
      # http://msdn.microsoft.com/en-us/library/windows/desktop/aa383742(v=vs.85).aspx
      def make_uint64(low, high)
        low + (high * (2**32))
      end

      # http://blogs.msdn.com/b/oldnewthing/archive/2009/03/06/9461176.aspx
      # January 1, 1601
      WIN32_EPOC_MINUS_POSIX_EPOC = 116444736000000000

      # Convert 64-bit FILETIME integer into Time object.
      #
      # FILETIME structure contains a 64-bit value representing the number
      # of 100-nanosecond intervals since January 1, 1601 (UTC).
      #
      # http://msdn.microsoft.com/en-us/library/ms724284(VS.85).aspx
      #
      def wtime_to_time(wtime)
        Time.at((wtime - WIN32_EPOC_MINUS_POSIX_EPOC) / 10000000)
      end

    end
  end
end
