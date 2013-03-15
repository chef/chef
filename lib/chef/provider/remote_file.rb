#
# Author:: Jesse Campbell (<hikeit@gmail.com>)
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'chef/provider/file'

class Chef
  class Provider
    class RemoteFile < Chef::Provider::File

      def initialize(new_resource, run_context)
        @content_class = Chef::Provider::File::Content::RemoteFile
        super
      end

      def load_current_resource
        @current_resource = Chef::Resource::RemoteFile.new(@new_resource.name)
        super
        fileinfo = load_fileinfo
        if fileinfo && fileinfo["checksum"] == @current_resource.checksum
          @current_resource.etag fileinfo["etag"]
          @current_resource.last_modified fileinfo["last_modified"]
          @current_resource.source fileinfo["src"]
        end
      end

      def action_create
        super
        save_fileinfo(@content.raw_file_source)
      end

      private

      def load_fileinfo
        begin
          Chef::JSONCompat.from_json(Chef::FileCache.load("remote_file/#{new_resource.name}"))
        rescue Chef::Exceptions::FileNotFound
          nil
        end
      end

      def save_fileinfo(source)
        cache = Hash.new
        cache["etag"] = @new_resource.etag
        cache["last_modified"] = @new_resource.last_modified
        cache["src"] = source
        cache["checksum"] = @new_resource.checksum
        cache_path = new_resource.name.sub(/^([A-Za-z]:)/, "")  # strip drive letter on Windows
        Chef::FileCache.store("remote_file/#{cache_path}", cache.to_json)
      end
    end
  end
end

