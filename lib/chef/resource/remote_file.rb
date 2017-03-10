#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

require "uri"
require "chef/resource/file"
require "chef/provider/remote_file"
require "chef/mixin/securable"
require "chef/mixin/uris"

class Chef
  class Resource
    class RemoteFile < Chef::Resource::File
      include Chef::Mixin::Securable

      def initialize(name, run_context = nil)
        super
        @source = []
        @use_etag = true
        @use_last_modified = true
        @ftp_active_mode = false
        @headers = {}
        @provider = Chef::Provider::RemoteFile
      end

      # source can take any of the following as arguments
      # - A single string argument
      # - Multiple string arguments
      # - An array or strings
      # - A delayed evaluator that evaluates to a string
      #   or array of strings
      # All strings must be parsable as URIs.
      # source returns an array of strings.
      def source(*args)
        arg = parse_source_args(args)
        ret = set_or_return(:source,
                            arg,
                            { :callbacks => {
                                :validate_source => method(:validate_source),
                              } })
        if ret.is_a? String
          Array(ret)
        else
          ret
        end
      end

      def parse_source_args(args)
        if args.empty?
          nil
        elsif args[0].is_a?(Chef::DelayedEvaluator) && args.count == 1
          args[0]
        elsif args.any? { |a| a.is_a?(Chef::DelayedEvaluator) } && args.count > 1
          raise Exceptions::InvalidRemoteFileURI, "Only 1 source argument allowed when using a lazy evaluator"
        else
          Array(args).flatten
        end
      end

      def checksum(args = nil)
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

      def use_etag(args = nil)
        set_or_return(
          :use_etag,
          args,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      alias :use_etags :use_etag

      def use_last_modified(args = nil)
        set_or_return(
          :use_last_modified,
          args,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      def ftp_active_mode(args = nil)
        set_or_return(
          :ftp_active_mode,
          args,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      def headers(args = nil)
        set_or_return(
          :headers,
          args,
          :kind_of => Hash
        )
      end

      def show_progress(args = nil)
        set_or_return(
          :show_progress,
          args,
          :default => false,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      private

      include Chef::Mixin::Uris

      def validate_source(source)
        source = Array(source).flatten
        raise ArgumentError, "#{resource_name} has an empty source" if source.empty?
        source.each do |src|
          unless absolute_uri?(src)
            raise Exceptions::InvalidRemoteFileURI,
              "#{src.inspect} is not a valid `source` parameter for #{resource_name}. `source` must be an absolute URI or an array of URIs."
          end
        end
        true
      end

      def absolute_uri?(source)
        Chef::Provider::RemoteFile::Fetcher.network_share?(source) || (source.kind_of?(String) && as_uri(source).absolute?)
      rescue URI::InvalidURIError
        false
      end

    end
  end
end
