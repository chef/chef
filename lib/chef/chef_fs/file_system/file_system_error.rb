#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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
  module ChefFS
    module FileSystem
      class FileSystemError < StandardError
        # @param entry The entry which had an issue.
        # @param cause The wrapped exception (if any).
        # @param reason A string describing why this exception happened.
        def initialize(entry, cause = nil, reason = nil)
          super(reason)
          @entry = entry
          @cause = cause
          @reason = reason
        end

        # The entry which had an issue.
        attr_reader :entry

        # The wrapped exception (if any).
        attr_reader :cause

        # A string describing why this exception happened.
        attr_reader :reason
      end
    end
  end
end
