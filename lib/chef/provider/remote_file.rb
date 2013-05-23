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
require 'chef/deprecation/provider/remote_file'
require 'chef/deprecation/warnings'

class Chef
  class Provider
    class RemoteFile < Chef::Provider::File

      extend Chef::Deprecation::Warnings
      include Chef::Deprecation::Provider::RemoteFile
      add_deprecation_warnings_for(Chef::Deprecation::Provider::RemoteFile.instance_methods)

      def initialize(new_resource, run_context)
        @content_class = Chef::Provider::RemoteFile::Content
        super
      end

      def load_current_resource
        @current_resource = Chef::Resource::RemoteFile.new(@new_resource.name)
        super
      end

      private

      def do_contents_changes
        super
        update_new_resource_checksum
      end

      def update_new_resource_checksum
        return if tempfile.nil?  # we 304'd, so have no etags or last-modified
        unless whyrun_mode?
          @new_resource.checksum(checksum(@new_resource.path)) unless @new_resource.checksum
          save_fileinfo(@content.raw_file_source)
        end
      end

      def fileinfo
        @fileinfo ||= begin
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
        Chef::Log.debug("stored etag '%s', last_modified '%s', checksum '%s' for source '%s' into %s" % [cache["etag"], cache["last_modified"], cache["checksum"], source, "#{Chef::Config[:file_cache_path]}/remote_file/#{cache_path}"] )
      end
    end
  end
end

