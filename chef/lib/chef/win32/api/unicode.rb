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
      module Unicode
        extend Chef::ReservedNames::Win32::API

        ###############################################
        # Win32 API Constants
        ###############################################

        CP_ACP         = 0
        CP_OEMCP       = 1
        CP_MACCP       = 2
        CP_THREAD_ACP  = 3
        CP_SYMBOL      = 42
        CP_UTF7        = 65000
        CP_UTF8        = 65001

        MB_PRECOMPOSED       = 0x00000001
        MB_COMPOSITE         = 0x00000002
        MB_USEGLYPHCHARS     = 0x00000004
        MB_ERR_INVALID_CHARS = 0x00000008

        WC_COMPOSITECHECK    = 0x00000200
        WC_DISCARDNS         = 0x00000010
        WC_SEPCHARS          = 0x00000020
        WC_DEFAULTCHAR       = 0x00000040
        WC_NO_BEST_FIT_CHARS = 0x00000400

        ANSI_CHARSET        = 0
        DEFAULT_CHARSET     = 1
        SYMBOL_CHARSET      = 2
        SHIFTJIS_CHARSET    = 128
        HANGEUL_CHARSET     = 129
        HANGUL_CHARSET      = 129
        GB2312_CHARSET      = 134
        CHINESEBIG5_CHARSET = 136
        OEM_CHARSET         = 255
        JOHAB_CHARSET       = 130
        HEBREW_CHARSET      = 177
        ARABIC_CHARSET      = 178
        GREEK_CHARSET       = 161
        TURKISH_CHARSET     = 162
        VIETNAMESE_CHARSET  = 163
        THAI_CHARSET        = 222
        EASTEUROPE_CHARSET  = 238
        RUSSIAN_CHARSET     = 204

        IS_TEXT_UNICODE_ASCII16            = 0x0001
        IS_TEXT_UNICODE_REVERSE_ASCII16    = 0x0010
        IS_TEXT_UNICODE_STATISTICS         = 0x0002
        IS_TEXT_UNICODE_REVERSE_STATISTICS = 0x0020
        IS_TEXT_UNICODE_CONTROLS           = 0x0004
        IS_TEXT_UNICODE_REVERSE_CONTROLS   = 0x0040
        IS_TEXT_UNICODE_SIGNATURE          = 0x0008
        IS_TEXT_UNICODE_REVERSE_SIGNATURE  = 0x0080
        IS_TEXT_UNICODE_ILLEGAL_CHARS      = 0x0100
        IS_TEXT_UNICODE_ODD_LENGTH         = 0x0200
        IS_TEXT_UNICODE_DBCS_LEADBYTE      = 0x0400
        IS_TEXT_UNICODE_NULL_BYTES         = 0x1000
        IS_TEXT_UNICODE_UNICODE_MASK       = 0x000F
        IS_TEXT_UNICODE_REVERSE_MASK       = 0x00F0
        IS_TEXT_UNICODE_NOT_UNICODE_MASK   = 0x0F00
        IS_TEXT_UNICODE_NOT_ASCII_MASK     = 0xF000

        TCI_SRCCHARSET  = 1
        TCI_SRCCODEPAGE = 2
        TCI_SRCFONTSIG  = 3
        TCI_SRCLOCALE   = 0x100

        ###############################################
        # Win32 API Bindings
        ###############################################

        ffi_lib 'kernel32', 'advapi32'

=begin
BOOL IsTextUnicode(
  __in     const VOID *lpv,
  __in     int iSize,
  __inout  LPINT lpiResult
);
=end
        attach_function :IsTextUnicode, [:pointer, :int, :LPINT], :BOOL

=begin
int MultiByteToWideChar(
  __in   UINT CodePage,
  __in   DWORD dwFlags,
  __in   LPCSTR lpMultiByteStr,
  __in   int cbMultiByte,
  __out  LPWSTR lpWideCharStr,
  __in   int cchWideChar
);
=end
        attach_function :MultiByteToWideChar, [:UINT, :DWORD, :LPCSTR, :int, :LPWSTR, :int], :int

=begin
int WideCharToMultiByte(
  __in   UINT CodePage,
  __in   DWORD dwFlags,
  __in   LPCWSTR lpWideCharStr,
  __in   int cchWideChar,
  __out  LPSTR lpMultiByteStr,
  __in   int cbMultiByte,
  __in   LPCSTR lpDefaultChar,
  __out  LPBOOL lpUsedDefaultChar
);
=end
        attach_function :WideCharToMultiByte, [:UINT, :DWORD, :LPCWSTR, :int, :LPSTR, :int, :LPCSTR, :LPBOOL], :int

        ###############################################
        # Helpers
        ###############################################

        def utf8_to_wide(ustring)
          # ensure it is actually UTF-8
          # Ruby likes to mark binary data as ASCII-8BIT
          ustring = (ustring + "").force_encoding('UTF-8') if ustring.respond_to?(:force_encoding) && ustring.encoding.name != "UTF-8"

          # ensure we have the double-null termination Windows Wide likes
          ustring = ustring + "\000\000" if ustring[-1].chr != "\000"

          # encode it all as UTF-16LE AKA Windows Wide Character AKA Windows Unicode
          ustring = begin
            if ustring.respond_to?(:encode)
              ustring.encode('UTF-16LE')
            else
              require 'iconv'
              Iconv.conv("UTF-16LE", "UTF-8", ustring)
            end
          end
          ustring
        end

        def wide_to_utf8(wstring)
          # ensure it is actually UTF-16LE
          # Ruby likes to mark binary data as ASCII-8BIT
          wstring = wstring.force_encoding('UTF-16LE') if wstring.respond_to?(:force_encoding)

          # encode it all as UTF-8
          wstring = begin
            if wstring.respond_to?(:encode)
              wstring.encode('UTF-8')
            else
              require 'iconv'
              Iconv.conv("UTF-8", "UTF-16LE", wstring)
            end
          end
          # remove trailing CRLF and NULL characters
          wstring.strip!
          wstring
        end

      end
    end
  end
end
