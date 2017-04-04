#--
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

require "chef/cookbook/file_vendor"

class Chef
  class Cookbook
    # == Chef::Cookbook::FileSystemFileVendor
    # This FileVendor loads files from Chef::Config.cookbook_path. The
    # thing that's sort of janky about this FileVendor implementation is
    # that it basically takes only the cookbook's name from the manifest
    # and throws the rest away then re-builds the list of files on the
    # disk. This is due to the manifest not having the on-disk file
    # locations, since in the chef-client case, that information is
    # non-sensical.
    class FileSystemFileVendor < FileVendor

      attr_reader :cookbook_name
      attr_reader :repo_paths

      def initialize(manifest, *repo_paths)
        @cookbook_name = manifest.name
        @repo_paths = repo_paths.flatten
        raise ArgumentError, "You must specify at least one repo path" if repo_paths.empty?
      end

      def cookbooks
        @cookbooks ||= Chef::CookbookLoader.new(repo_paths).load_cookbooks
      end

      # Implements abstract base's requirement. It looks in the
      # Chef::Config.cookbook_path file hierarchy for the requested
      # file.
      def get_filename(filename)
        location = File.join(cookbooks[cookbook_name].root_dir, filename) if cookbooks.has_key?(cookbook_name)
        raise "File #{filename} does not exist for cookbook #{cookbook_name}" unless location && File.exist?(location)
        location
      end

    end
  end
end
