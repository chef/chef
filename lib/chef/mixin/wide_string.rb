#
# Author:: Jay Mundrawala(<jdm@chef.io>)
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

class Chef
  module Mixin
    module WideString

      def wstring(str)
        if str.nil? || str.encoding == Encoding::UTF_16LE
          str
        else
          utf8_to_wide(str)
        end
      end

      def utf8_to_wide(ustring)
        # ensure it is actually UTF-8
        # Ruby likes to mark binary data as ASCII-8BIT
        ustring = (ustring + "").force_encoding("UTF-8")

        # ensure we have the double-null termination Windows Wide likes
        ustring += "\000\000" if ustring.length == 0 || ustring[-1].chr != "\000"

        # encode it all as UTF-16LE AKA Windows Wide Character AKA Windows Unicode
        ustring.encode("UTF-16LE")
      end

      def wide_to_utf8(wstring)
        # ensure it is actually UTF-16LE
        # Ruby likes to mark binary data as ASCII-8BIT
        wstring = wstring.force_encoding("UTF-16LE")

        # encode it all as UTF-8 and remove trailing CRLF and NULL characters
        wstring.encode("UTF-8").strip
      end

    end
  end
end
