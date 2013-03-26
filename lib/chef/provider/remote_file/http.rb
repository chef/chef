#
# Author:: Jesse Campbell (<hikeit@gmail.com>)
# Author:: Lamont Granquist (<lamont@opscode.com>)
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
require 'chef/rest'
require 'chef/provider/remote_file'
require 'chef/provider/remote_file/util'
require 'chef/provider/remote_file/result'

class Chef
  class Provider
    class RemoteFile
      class HTTP

        # Parse the uri into instance variables
        def initialize(uri, new_resource, current_resource)
          @headers = Hash.new
          if current_resource.source && Chef::Provider::RemoteFile::Util.uri_matches_string?(uri, current_resource.source[0])
            if current_resource.use_etag && current_resource.etag
              @headers['if-none-match'] = "\"#{current_resource.etag}\""
            end
            if current_resource.use_last_modified && current_resource.last_modified
              @headers['if-modified-since'] = current_resource.last_modified.strftime("%a, %d %b %Y %H:%M:%S %Z")
            end
          end
          @uri = uri
        end

        def fetch
          begin
            rest = Chef::REST.new(@uri, nil, nil, http_client_opts)
            tempfile = rest.streaming_request(@uri, @headers)
            if rest.last_response['last_modified']
              mtime = Time.parse(rest.last_response['last_modified'])
            elsif rest.last_response['date']
              mtime = Time.parse(rest.last_response['date'])
            else
              mtime = Time.now
            end
            if rest.last_response['etag']
              etag = rest.last_response['etag']
            else
              etag = nil
            end
          rescue Net::HTTPRetriableError => e
            if e.response.is_a? Net::HTTPNotModified
              tempfile = nil
            else
              raise e
            end
          end
          return Chef::Provider::RemoteFile::Result.new(tempfile, etag, mtime)
        end

        private

        def http_client_opts
          opts={}
          # CHEF-3140
          # 1. If it's already compressed, trying to compress it more will
          # probably be counter-productive.
          # 2. Some servers are misconfigured so that you GET $URL/file.tgz but
          # they respond with content type of tar and content encoding of gzip,
          # which tricks Chef::REST into decompressing the response body. In this
          # case you'd end up with a tar archive (no gzip) named, e.g., foo.tgz,
          # which is not what you wanted.
          if @uri.to_s =~ /gz$/
            opts[:disable_gzip] = true
          end
          opts
        end

      end
    end
  end
end
