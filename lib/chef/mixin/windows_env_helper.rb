#
# Author:: Adam Edwards (<adamed@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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

require "chef/exceptions"
require "chef/mixin/wide_string"
require "chef/platform/query_helpers"
require "chef/win32/error" if Chef::Platform.windows?
require "chef/win32/api/system" if Chef::Platform.windows?
require "chef/win32/api/unicode" if Chef::Platform.windows?

class Chef
  module Mixin
    module WindowsEnvHelper
      include Chef::Mixin::WideString

      if Chef::Platform.windows?
        include Chef::ReservedNames::Win32::API::System
      end

      #see: http://msdn.microsoft.com/en-us/library/ms682653%28VS.85%29.aspx
      HWND_BROADCAST = 0xffff
      WM_SETTINGCHANGE = 0x001A
      SMTO_BLOCK = 0x0001
      SMTO_ABORTIFHUNG = 0x0002
      SMTO_NOTIMEOUTIFNOTHUNG = 0x0008

      def broadcast_env_change
        flags = SMTO_BLOCK | SMTO_ABORTIFHUNG | SMTO_NOTIMEOUTIFNOTHUNG
        # for why two calls, see:
        # http://stackoverflow.com/questions/4968373/why-doesnt-sendmessagetimeout-update-the-environment-variables
        if SendMessageTimeoutA(HWND_BROADCAST, WM_SETTINGCHANGE, 0, FFI::MemoryPointer.from_string("Environment").address, flags, 5000, nil) == 0
          Chef::ReservedNames::Win32::Error.raise!
        end
        if  SendMessageTimeoutW(HWND_BROADCAST, WM_SETTINGCHANGE, 0, FFI::MemoryPointer.from_string(
            utf8_to_wide("Environment")
        ).address, flags, 5000, nil) == 0
          Chef::ReservedNames::Win32::Error.raise!
        end
      end

      def expand_path(path)
        # http://msdn.microsoft.com/en-us/library/windows/desktop/ms724265%28v=vs.85%29.aspx
        # Max size of env block on windows is 32k
        buf = 0.chr * 32 * 1024
        if ExpandEnvironmentStringsA(path, buf, buf.length) == 0
          Chef::ReservedNames::Win32::Error.raise!
        end
        buf.strip
      end
    end
  end
end
