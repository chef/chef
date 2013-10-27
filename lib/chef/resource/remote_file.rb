#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2008, 2011 Opscode, Inc.
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

require 'chef/resource/file'
require 'chef/provider/remote_file'
require 'chef/mixin/securable'

class Chef
  class Resource
    class RemoteFile < Chef::Resource::File
      include Chef::Mixin::Securable

      provides :remote_file, :on_platforms => :all

      def initialize(name, run_context=nil)
        super
        @resource_name = :remote_file
        @action = "create"
        @source = []
        @use_etag = true
        @use_last_modified = true
        @ftp_active_mode = false
        @headers = {}
        @provider = Chef::Provider::RemoteFile
      end

      def source(*args)
        if not args.empty?
          args = Array(args).flatten
          validate_source(args)
          @source = args
        elsif self.instance_variable_defined?(:@source) == true
          @source
        end
      end

      def checksum(args=nil)
        set_or_return(
          :checksum,
          args,
          :kind_of => String
        )
      end

      # Disable or enable ETag and Last Modified conditional GET. Equivalent to
      #   use_etag(true_or_false)
      #   use_last_modified(true_or_false)
      def use_conditional_get(true_or_false)
        use_etag(true_or_false)
        use_last_modified(true_or_false)
      end

      def use_etag(args=nil)
        set_or_return(
          :use_etag,
          args,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      alias :use_etags :use_etag

      def use_last_modified(args=nil)
        set_or_return(
          :use_last_modified,
          args,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      def ftp_active_mode(args=nil)
        set_or_return(
          :ftp_active_mode,
          args,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      def headers(args=nil)
        set_or_return(
          :headers,
          args,
          :kind_of => Hash
        )
      end

      def after_created
        validate_source(@source)
      end

      private

      def validate_source(source)
        raise ArgumentError, "#{resource_name} has an empty source" if source.empty?
        source.each do |src|
          unless absolute_uri?(src)
            raise Exceptions::InvalidRemoteFileURI,
              "#{src.inspect} is not a valid `source` parameter for #{resource_name}. `source` must be an absolute URI or an array of URIs."
          end
        end
      end

      def absolute_uri?(source)
        source.kind_of?(String) and URI.parse(source).absolute?
      rescue URI::InvalidURIError
        false
      end

    end
  end
end
