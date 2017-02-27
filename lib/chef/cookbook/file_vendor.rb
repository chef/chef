#
# Author:: Christopher Walters (<cw@chef.io>)
# Author:: Tim Hinderliter (<tim@chef.io>)
# Copyright:: Copyright 2010-2016, Chef Software Inc.
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

class Chef
  class Cookbook
    # == Chef::Cookbook::FileVendor
    # This class handles fetching of cookbook files based on specificity.
    class FileVendor

      @vendor_class = nil
      @initialization_options = nil

      # Configures FileVendor to use the RemoteFileVendor implementation. After
      # calling this, subsequent calls to create_from_manifest will return a
      # RemoteFileVendor object initialized with the given http_client
      def self.fetch_from_remote(http_client)
        @vendor_class = RemoteFileVendor
        @initialization_options = http_client
      end

      def self.fetch_from_disk(cookbook_paths)
        @vendor_class = FileSystemFileVendor
        @initialization_options = cookbook_paths
      end

      # Returns the implementation class that is currently configured, or `nil`
      # if one has not been configured yet.
      def self.vendor_class
        @vendor_class
      end

      def self.initialization_options
        @initialization_options
      end

      # Factory method that creates the appropriate kind of
      # Cookbook::FileVendor to serve the contents of the manifest
      def self.create_from_manifest(manifest)
        if @vendor_class.nil?
          raise "Must configure FileVendor to use a specific implementation before creating an instance"
        end
        @vendor_class.new(manifest, @initialization_options)
      end

      # Gets the on-disk location for the given cookbook file.
      #
      # Subclasses are responsible for determining exactly how the
      # files are obtained and where they are stored.
      def get_filename(filename)
        raise NotImplemented, "Subclasses must implement this method"
      end

    end
  end
end
