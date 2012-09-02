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
        source(::File.basename(name))
        @cookbook = nil
        @provider = Chef::Provider::RemoteFile
      end

      def source(*args)
        if not args.empty?
          args = Array(args).flatten
          args.each do |arg|
            raise Exceptions::ValidationFailed, "Option source must be a kind of String!  You passed #{arg.inspect}." unless arg.kind_of?(String)
          end
          @source = args
        elsif self.instance_variable_defined?(:@source) == true
          @source
        end
      end

      def cookbook(args=nil)
        set_or_return(
          :cookbook,
          args,
          :kind_of => String
        )
      end

      def checksum(args=nil)
        set_or_return(
          :checksum,
          args,
          :kind_of => String
        )
      end

      # The provider that should be used for this resource.
      # === Returns:
      # Chef::Provider::RemoteFile    when the source is an absolute URI, like
      #                               http://www.google.com/robots.txt or an Array of URIs.
      # Chef::Provider::CookbookFile  when the source is a relative URI, like
      #                               'myscript.pl', 'dir/config.conf'.
      #                               Array of CookbookFiles is not currently supported.
      def provider
        if source.kind_of?(String)
          Chef::Provider::CookbookFile
        elsif source.length == 1 and not absolute_uri?(source[0])
          @source = source[0]
          Chef::Log.warn("remote_file is deprecated for fetching files from cookbooks. Use cookbook_file instead")
          Chef::Log.warn("From #{self.to_s} on #{source_line}")
          Chef::Provider::CookbookFile
        else
          sources = []
          source.each do |src|
            if absolute_uri?(src)
              sources.push(src)
            else
              Chef::Log.warn("remote_file is deprecated for fetching files from cookbooks. Cookbook files inside the source array will be ignored. Use cookbook_file instead")
            end
          end
          source(sources)
          Chef::Provider::RemoteFile
        end
      end

      private

      def absolute_uri?(source)
        URI.parse(source).absolute?
      rescue URI::InvalidURIError
        false
      end

    end
  end
end
