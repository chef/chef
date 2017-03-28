#--
# Copyright:: Copyright 2017, Chef Software Inc.
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

require "singleton"

class Chef
  class ServerAPIVersions
    include Singleton

    def set_versions(versions)
      @versions ||= versions
    end

    def min_server_version
      !@versions.nil? ? Integer(@versions["min_version"]) : nil
    end

    def max_server_version
      !@versions.nil? ? Integer(@versions["max_version"]) : nil
    end

    def reset!
      @versions = nil
    end
  end
end
