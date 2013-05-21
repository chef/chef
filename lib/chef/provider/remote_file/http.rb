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

      class CacheControlData
        attr_accessor :etag
        attr_accessor :mtime

      end

      class HTTP

        attr_reader :uri
        attr_reader :new_resource
        attr_reader :current_resource

        # Parse the uri into instance variables
        def initialize(uri, new_resource, current_resource)
          @uri = uri
          @new_resource = new_resource
          @current_resource = current_resource
        end

        def headers
          conditional_get_headers.merge(new_resource.headers)
        end

        def conditional_get_headers
          cache_control_headers = {}
          cache_control_data = CacheControlData.load_and_validate(uri, current_resource.checksum)
          if last_modified = cache_control_data.mtime and want_mtime_cache_control?
            cache_control_headers["if-modified-since"] = last_modified
          end
          if etag = cache_control_data.etag and want_etag_cache_control?
            cache_control_headers["if-none-match"] = etag
          end
          Chef::Log.debug("Cache control headers: #{cache_control_headers.inspect}")
          cache_control_headers
        end

        def fetch
          begin
            rest = Chef::REST.new(uri, nil, nil, http_client_opts)
            tempfile = rest.streaming_request(uri, headers)
            mtime = last_modified_time_from(rest.last_response)
            etag = etag_from(rest.last_response)
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

        def want_mtime_cache_control?
          new_resource.use_last_modified || new_resource.use_conditional_get
        end

        def want_etag_cache_control?
          new_resource.use_etag || new_resource.use_conditional_get
        end

        def last_modified_time_from(response)
          if mtime_header = response['last_modified'] || response['date']
            Time.parse(mtime_header)
          else
            nil
          end
        end

        def etag_from(response)
          response['etag']
        end

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
          if uri.to_s =~ /gz$/
            Chef::Log.debug("turning gzip compression off due to filename ending in gz")
            opts[:disable_gzip] = true
          end
          opts
        end

      end
    end
  end
end
