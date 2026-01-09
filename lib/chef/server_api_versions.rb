#--
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

require "singleton" unless defined?(Singleton)

class Chef
  class ServerAPIVersions
    include Singleton

    def set_versions(versions)
      @versions ||= versions
    end

    def min_server_version
      # If we're working with a pre-api-versioning server, always claim to be zero
      if @versions.nil?
        unversioned? ? 0 : nil
      else
        Integer(@versions["min_version"])
      end
    end

    def max_server_version
      # If we're working with a pre-api-versioning server, always claim to be zero
      if @versions.nil?
        unversioned? ? 0 : nil
      else
        Integer(@versions["max_version"])
      end
    end

    def unversioned!
      @unversioned = true
    end

    def unversioned?
      @unversioned
    end

    def negotiated?
      !@versions.nil? || unversioned?
    end

    def reset!
      @versions = nil
      @unversioned = false
    end
  end
end
