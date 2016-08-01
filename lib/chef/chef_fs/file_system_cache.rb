#
# Copyright:: Copyright 2016, Chef Software Inc.
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
require "chef/client"

class Chef
  module ChefFS
    class FileSystemCache
      include Singleton

      def initialize
        @cache = {}

        Chef::Client.when_run_starts do
          FileSystemCache.instance.reset!
        end
      end

      def reset!
        @cache = {}
      end

      def exist?(path)
        @cache.key?(path)
      end

      def children(path)
        @cache[path]["children"]
      end

      def set_children(path, val)
        @cache[path] ||= { "children" => [] }
        @cache[path]["children"] = val
        val
      end

      def delete!(path)
        parent = _get_parent(path)
        Chef::Log.debug("Deleting parent #{parent} and #{path} from FileSystemCache")
        if @cache.key?(path)
          @cache.delete(path)
        end
        if !parent.nil? && @cache.key?(parent)
          @cache.delete(parent)
        end
      end

      def fetch(path)
        if @cache.key?(path)
          @cache[path]
        else
          false
        end
      end

      private

      def _get_parent(path)
        parts = ChefFS::PathUtils.split(path)
        return nil if parts.nil? || parts.length < 2
        ChefFS::PathUtils.join(*parts[0..-2])
      end
    end
  end
end
