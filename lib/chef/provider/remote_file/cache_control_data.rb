#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: Jesse Campbell (<hikeit@gmail.com>)
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright:: Copyright (c) 2013 Jesse Campbell
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require 'stringio'
require 'chef/file_cache'
require 'chef/json_compat'
require 'chef/digester'
require 'chef/exceptions'

class Chef
  class Provider
    class RemoteFile
      class CacheControlData

        def self.load_and_validate(uri, current_copy_checksum)
          ccdata = new(uri)
          ccdata.load
          ccdata.validate!(current_copy_checksum)
          ccdata
        end

        attr_accessor :etag
        attr_accessor :mtime
        attr_accessor :checksum

        attr_reader :uri

        def initialize(uri)
          @uri = uri.to_s
        end

        def load
          previous_cc_data = load_data
          apply(previous_cc_data)
          self
        rescue Chef::Exceptions::FileNotFound
          false
        end

        def validate!(current_copy_checksum)
          if current_copy_checksum.nil? or checksum != current_copy_checksum
            reset!
            false
          else
            true
          end
        end

        def save
          Chef::FileCache.store("remote_file/#{sanitized_cache_file_basename}", json_data)
        end

        # :nodoc:
        # JSON representation of this object for storage.
        def json_data
          Chef::JSONCompat.to_json(hash_data)
        end

        private

        def hash_data
          as_hash = {}
          as_hash["etag"]     = etag
          as_hash["mtime"]    = mtime
          as_hash["checksum"] = checksum
          as_hash
        end

        def reset!
          @etag, @mtime = nil, nil
        end

        def apply(previous_cc_data)
          @etag = previous_cc_data["etag"]
          @mtime = previous_cc_data["mtime"]
          @checksum = previous_cc_data["checksum"]
        end

        def load_data
          Chef::JSONCompat.from_json(load_json_data)
        end

        def load_json_data
          Chef::FileCache.load("remote_file/#{sanitized_cache_file_basename}")
        end

        def sanitized_cache_file_basename
          scrubbed_uri = uri.gsub(/\W/, '_')
          uri_md5 = Chef::Digester.instance.generate_md5_checksum(StringIO.new(uri))
          "#{scrubbed_uri}-#{uri_md5}.json"
        end

      end
    end
  end
end


