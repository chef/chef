#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require 'chef/chef_fs/path_utils'
require 'chef/chef_fs/file_system/operation_not_allowed_error'

class Chef
  module ChefFS
    module FileSystem
      class BaseFSObject
        def initialize(name, parent)
          @parent = parent
          @name = name
          if parent
            @path = Chef::ChefFS::PathUtils::join(parent.path, name)
          else
            if name != ''
              raise ArgumentError, "Name of root object must be empty string: was '#{name}' instead"
            end
            @path = '/'
          end
        end

        attr_reader :name
        attr_reader :parent
        attr_reader :path

        # Override this if you have a special comparison algorithm that can tell
        # you whether this entry is the same as another--either a quicker or a
        # more reliable one.  Callers will use this to decide whether to upload,
        # download or diff an object.
        #
        # You should not override this if you're going to do the standard
        # +self.read == other.read+.  If you return +nil+, the caller will call
        # +other.compare_to(you)+ instead.  Give them a chance :)
        #
        # ==== Parameters
        #
        # * +other+ - the entry to compare to
        #
        # ==== Returns
        #
        # * +[ are_same, value, other_value ]+
        #   +are_same+ may be +true+, +false+ or +nil+ (which means "don't know").
        #   +value+ and +other_value+ must either be the text of +self+ or +other+,
        #   +:none+ (if the entry does not exist or has no value) or +nil+ if the
        #   value was not retrieved.
        # * +nil+ if a definitive answer cannot be had and nothing was retrieved.
        #
        # ==== Example
        #
        #     are_same, value, other_value = entry.compare_to(other)
        #     if are_same.nil?
        #       are_same, other_value, value = other.compare_to(entry)
        #     end
        #     if are_same.nil?
        #       value = entry.read if value.nil?
        #       other_value = entry.read if other_value.nil?
        #       are_same = (value == other_value)
        #     end
        def compare_to(other)
          nil
        end

        # Override can_have_child? to report whether a given file *could* be added
        # to this directory.  (Some directories can't have subdirs, some can only have .json
        # files, etc.)
        def can_have_child?(name, is_dir)
          false
        end

        # Get a child of this entry with the given name.  This MUST always
        # return a child, even if it is NonexistentFSObject.  Overriders should
        # take caution not to do expensive network requests to get the list of
        # children to fulfill this request, unless absolutely necessary here; it
        # is intended as a quick way to traverse a hierarchy.
        #
        # For example, knife show /data_bags/x/y.json will call
        # root.child('data_bags').child('x').child('y.json'), which can then
        # directly perform a network request to retrieve the y.json data bag.  No
        # network request was necessary to retrieve
        def child(name)
          NonexistentFSObject.new(name, self)
        end

        # Override children to report your *actual* list of children as an array.
        def children
          raise NotFoundError.new(self) if !exists?
          []
        end

        def chef_hash
          raise NotFoundError.new(self) if !exists?
          nil
        end

        # Expand this entry into a chef object (Chef::Role, ::Node, etc.)
        def chef_object
          raise NotFoundError.new(self) if !exists?
          nil
        end

        # Create a child of this entry with the given name and contents.  If
        # contents is nil, create a directory.
        #
        # NOTE: create_child_from is an optional method that can also be added to
        # your entry class, and will be called without actually reading the
        # file_contents.  This is used for knife upload /cookbooks/cookbookname.
        def create_child(name, file_contents)
          raise NotFoundError.new(self) if !exists?
          raise OperationNotAllowedError.new(:create_child, self)
        end

        # Delete this item, possibly recursively.  Entries MUST NOT delete a
        # directory unless recurse is true.
        def delete(recurse)
          raise NotFoundError.new(self) if !exists?
          raise OperationNotAllowedError.new(:delete, self)
        end

        # Ask whether this entry is a directory.  If not, it is a file.
        def dir?
          false
        end

        # Ask whether this entry exists.
        def exists?
          true
        end

        # Printable path, generally used to distinguish paths in one root from
        # paths in another.
        def path_for_printing
          if parent
            parent_path = parent.path_for_printing
            if parent_path == '.'
              name
            else
              Chef::ChefFS::PathUtils::join(parent.path_for_printing, name)
            end
          else
            name
          end
        end

        def root
          parent ? parent.root : self
        end

        # Read the contents of this file entry.
        def read
          raise NotFoundError.new(self) if !exists?
          raise OperationNotAllowedError.new(:read, self)
        end

        # Write the contents of this file entry.
        def write(file_contents)
          raise NotFoundError.new(self) if !exists?
          raise OperationNotAllowedError.new(:write, self)
        end

        # Important directory attributes: name, parent, path, root
        # Overridable attributes: dir?, child(name), path_for_printing
        # Abstract: read, write, delete, children, can_have_child?, create_child, compare_to

        # Consider putting this into a concern module and including it instead
        def raw_request(_api_path)
          self.class.api_request(rest, :GET, rest.create_url(_api_path), {}, false)
        end


        class << self
          # Copied so that it does not automatically inflate an object
          # This is also used by knife raw_essentials

          ACCEPT_ENCODING = "Accept-Encoding".freeze
          ENCODING_GZIP_DEFLATE = "gzip;q=1.0,deflate;q=0.6,identity;q=0.3".freeze

          def redirected_to(response)
            return nil  unless response.kind_of?(Net::HTTPRedirection)
            # Net::HTTPNotModified is undesired subclass of Net::HTTPRedirection so test for this
            return nil  if response.kind_of?(Net::HTTPNotModified)
            response['location']
          end


          def build_headers(chef_rest, method, url, headers={}, json_body=false, raw=false)
            #        headers                 = @default_headers.merge(headers)
            #headers['Accept']       = "application/json" unless raw
            headers['Accept']       = "application/json" unless raw
            headers["Content-Type"] = 'application/json' if json_body
            headers['Content-Length'] = json_body.bytesize.to_s if json_body
            headers[Chef::REST::RESTRequest::ACCEPT_ENCODING] = Chef::REST::RESTRequest::ENCODING_GZIP_DEFLATE
            headers.merge!(chef_rest.authentication_headers(method, url, json_body)) if chef_rest.sign_requests?
            headers.merge!(Chef::Config[:custom_http_headers]) if Chef::Config[:custom_http_headers]
            headers
          end

          def api_request(chef_rest, method, url, headers={}, data=false)
            json_body = data
            #        json_body = data ? Chef::JSONCompat.to_json(data) : nil
            # Force encoding to binary to fix SSL related EOFErrors
            # cf. http://tickets.opscode.com/browse/CHEF-2363
            # http://redmine.ruby-lang.org/issues/5233
            #        json_body.force_encoding(Encoding::BINARY) if json_body.respond_to?(:force_encoding)
            headers = build_headers(chef_rest, method, url, headers, json_body)

            chef_rest.retriable_rest_request(method, url, json_body, headers) do |rest_request|
              response = rest_request.call {|r| r.read_body}

              response_body = chef_rest.decompress_body(response)

              if response.kind_of?(Net::HTTPSuccess)
                  response_body
              elsif redirect_location = redirected_to(response)
                raise "Redirected to #{create_url(redirect_location)}"
                follow_redirect {api_request(:GET, create_url(redirect_location))}
              else
                # have to decompress the body before making an exception for it. But the body could be nil.
                response.body.replace(chef_rest.decompress_body(response)) if response.body.respond_to?(:replace)

                if response['content-type'] =~ /json/
                  exception = response_body
                  msg = "HTTP Request Returned #{response.code} #{response.message}: "
                  msg << (exception["error"].respond_to?(:join) ? exception["error"].join(", ") : exception["error"].to_s)
                  Chef::Log.info(msg)
                end
                response.error!
              end
            end
          end
        end

      end # class BaseFsObject
    end
  end
end

require 'chef/chef_fs/file_system/nonexistent_fs_object'
