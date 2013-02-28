#
# Author:: Jesse Campbell (<hikeit@gmail.com>)
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
require 'chef/provider/remote_file'

class Chef
  class Provider
    class RemoteFile
      class HTTP

        # Fetches the file at uri, returning a Tempfile-like File handle
        def self.fetch(uri, proxy_uri, if_modified_since, if_none_match)
          request = HTTP.new(uri, proxy_uri, if_modified_since, if_none_match)
          request.execute
        end

        # Parse the uri into instance variables
        def initialize(uri, proxy_uri, if_modified_since, if_none_match)
          RestClient.proxy = proxy_uri.to_s
          @headers = Hash.new
          if if_none_match
            @headers[:if_none_match] = "\"#{if_none_match}\""
          elsif if_modified_since
            @headers[:if_modified_since] = if_modified_since.strftime("%a, %d %b %Y %H:%M:%S %Z")
          end
          @uri = uri
        end

        def execute
          begin
            rest = RestClient::Request.execute(:method => :get, :url => @uri.to_s, :headers => @headers, :raw_response => true)
            raw_file = rest.file
						target_matched = false
            if rest.headers.include?(:last_modified)
              mtime = Time.parse(rest.headers[:last_modified])
						elsif rest.headers.include?(:date)
							mtime = Time.parse(rest.headers[:date])
						else
							mtime = Time.now
						end
            if rest.headers.include?(:etag)
              etag = rest.headers[:etag]
						else
							etag = nil
            end
          rescue RestClient::Exception => e
            if e.http_code == 304
              target_matched = true
            else
              raise e
            end
          end
          return raw_file, mtime, etag, target_matched
        end

      end
    end
  end
end
