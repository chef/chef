#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "../../win32/api/registry"
require_relative "../../win32/unicode"
require "win32/registry" unless defined?(Win32::Registry)

module Win32
  class Registry

    # ::Win32::Registry#export_string is used when enumerating child
    # keys and values and re encodes a UTF-16LE to the local codepage.
    # This can result in encoding incompatibilities if the native codepage
    # does not support the characters in the registry. There is an open bug
    # in ruby at https://bugs.ruby-lang.org/issues/11410. Rather than converting
    # the UTF-16LE originally returned by the win32 api, we encode to UTF-8
    # which will likely not result in any conversion error.
    def export_string(str, enc = Encoding.default_internal || "utf-8")
      str.encode(enc)
    end

    module API

      extend Chef::ReservedNames::Win32::API::Registry

      module_function

      # ::Win32::Registry#delete_value uses RegDeleteValue which
      # is not an imported function after bug 10820 was solved.  So
      # we overwrite it to call the correct imported function.
      # https://bugs.ruby-lang.org/issues/10820
      # Still a bug in trunk as of March 21, 2016 (Ruby 2.3.0)
      def DeleteValue(hkey, name)
        check RegDeleteValueW(hkey, name.to_wstring)
      end

      # ::Win32::Registry#delete_key uses RegDeleteKeyW. We need to use
      # RegDeleteKeyExW to properly support WOW64 systems.
      # Still a bug in trunk as of March 21, 2016 (Ruby 2.3.0)
      def DeleteKey(hkey, name)
        check RegDeleteKeyExW(hkey, name.to_wstring, 0, 0)
      end

    end
  end
end
