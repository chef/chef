#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Author:: Jesse Campbell (<hikeit@gmail.com>)
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2013-2016, Jesse Campbell
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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

require "stringio"
require "chef/file_cache"
require "chef/json_compat"
require "chef/digester"
require "chef/exceptions"

class Chef
  class Provider
    class RemoteFile

      # == CacheControlData
      # Implements per-uri storage of cache control data for a remote resource
      # along with a sanity check checksum of the file in question.
      # Provider::RemoteFile protocol implementation classes can use this
      # information to avoid re-fetching files when the current copy is up to
      # date. The way this information is used is protocol-dependent. For HTTP,
      # this information is sent to the origin server via headers to make a
      # conditional GET request.
      #
      # == API
      # The general shape of the API is active-record-the-pattern-like. New
      # instances should be instantiated via
      # `CacheControlData.load_and_validate`, which will do a find-or-create
      # operation and then sanity check the data against the checksum of the
      # current copy of the file. If there is no data or the sanity check
      # fails, the `etag` and `mtime` attributes will be set to nil; otherwise
      # they are populated with the previously saved values.
      #
      # After fetching a file, the CacheControlData instance should be updated
      # with new etag, mtime and checksum values in whatever format is
      # preferred by the protocol used. Then call #save to save the data to disk.
      class CacheControlData

        def self.load_and_validate(uri, current_copy_checksum)
          ccdata = new(uri)
          ccdata.load
          ccdata.validate!(current_copy_checksum)
          ccdata
        end

        # Entity Tag of the resource. HTTP-specific. See also:
        # http://www.w3.org/Protocols/rfc2616/rfc2616-sec13.html#sec13.3.2
        # http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.19
        attr_accessor :etag

        # Last modified time of the remote resource. Different protocols will
        # use different types for this field (e.g., string representation of a
        # specific date format, integer, etc.) For HTTP-specific references,
        # see:
        # * http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.3
        # * http://www.w3.org/Protocols/rfc2616/rfc2616-sec13.html#sec13.3.1
        # * http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.25
        attr_accessor :mtime

        # SHA2-256 Hash of the file as last fetched.
        attr_accessor :checksum

        # URI of the resource as a String. This is the "primary key" used for
        # storage and retrieval.
        attr_reader :uri

        def initialize(uri)
          uri = uri.dup
          uri.password = "XXXX" unless uri.userinfo.nil?
          @uri = uri.to_s
        end

        def load
          if previous_cc_data = load_data
            apply(previous_cc_data)
            self
          else
            false
          end
        end

        def validate!(current_copy_checksum)
          if current_copy_checksum.nil? || checksum != current_copy_checksum
            reset!
            false
          else
            true
          end
        end

        # Saves the data to disk using Chef::FileCache. The filename is a
        # sanitized version of the URI with a MD5 of the same URI appended (to
        # avoid collisions between different URIs having the same sanitized
        # form).
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
          Chef::JSONCompat.parse(load_json_data)
        rescue Chef::Exceptions::FileNotFound, Chef::Exceptions::JSON::ParseError
          false
        end

        def load_json_data
          path = sanitized_cache_file_path(sanitized_cache_file_basename)
          if Chef::FileCache.has_key?(path)
            Chef::FileCache.load(path)
          else
            old_path = sanitized_cache_file_path(sanitized_cache_file_basename_md5)
            if Chef::FileCache.has_key?(old_path)
              # We found an old cache control data file. We started using sha256 instead of md5
              # to name these. Upgrade the file to the new name.
              Chef::Log.debug("Found old cache control data file at #{old_path}. Moving to #{path}.")
              Chef::FileCache.load(old_path).tap do |data|
                Chef::FileCache.store(path, data)
                Chef::FileCache.delete(old_path)
              end
            else
              raise Chef::Exceptions::FileNotFound
            end
          end
        end

        def sanitized_cache_file_path(basename)
          "remote_file/#{basename}"
        end

        def scrubbed_uri
          # Scrub and truncate in accordance with the goals of keeping the name
          # human-readable but within the bounds of local file system
          # path length limits
          uri.gsub(/\W/, "_")[0..63]
        end

        def sanitized_cache_file_basename
          uri_sha2 = Chef::Digester.instance.generate_checksum(StringIO.new(uri))
          cache_file_basename(uri_sha2[0, 32])
        end

        def sanitized_cache_file_basename_md5
          # Old way of creating the file basename
          uri_md5 = Chef::Digester.instance.generate_md5_checksum(StringIO.new(uri))
          cache_file_basename(uri_md5)
        end

        def cache_file_basename(checksum)
          "#{scrubbed_uri}-#{checksum}.json"
        end
      end
    end
  end
end
