#
# Copyright:: Copyright 2015 Chef Software, Inc.
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

require 'chef/win32/api/registry'
require 'chef/win32/unicode'
require 'win32/registry'

module Win32
  class Registry
    module API
      
      extend Chef::ReservedNames::Win32::API::Registry

      module_function

      if RUBY_VERSION =~ /^2\.1/
        # ::Win32::Registry#delete_value is broken in Ruby 2.1 (up to Ruby 2.1.6).
        # This should be resolved in a later release (see note #9 in link below).
        # https://bugs.ruby-lang.org/issues/10820
        def DeleteValue(hkey, name)
          check RegDeleteValueW(hkey, name.to_wstring)
        end
      end

      # ::Win32::Registry#delete_key uses RegDeleteKeyW. We need to use
      # RegDeleteKeyExW to properly support WOW64 systems.
      def DeleteKey(hkey, name)
        check RegDeleteKeyExW(hkey, name.to_wstring, 0, 0)
      end
      
    end
  end
end