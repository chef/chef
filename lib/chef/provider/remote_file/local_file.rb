#
# Author:: Jesse Campbell (<hikeit@gmail.com>)
# Copyright:: Copyright (c) 2013 Jesse Campbell
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

require 'uri'
require 'tempfile'
require 'chef/provider/remote_file'

class Chef
  class Provider
    class RemoteFile
      class LocalFile < ::File

        # Fetches the file at uri, returning a Tempfile-like File handle
        def self.fetch(uri, if_modified_since)
          raw_file = LocalFile.new(uri.path)
					mtime = raw_file.mtime
          target_matched = mtime && if_modified_since && mtime.to_i <= if_modified_since.to_i
					if target_matched
						raw_file.close
						raw_file = nil
					end
          return raw_file, mtime, target_matched
        end

        def close!
          close
        end

        # Parse the uri into instance variables
        def initialize(uri, mode="r")
          super(uri.path, mode)
        end

      end
    end
  end
end
