#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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

require "chef/chef_fs/file_system/chef_server/cookbooks_dir"
require "chef/chef_fs/file_system/chef_server/cookbook_artifact_dir"

class Chef
  module ChefFS
    module FileSystem
      module ChefServer
        #
        # /cookbook_artifacts
        #
        # Example children of /cookbook_artifacts:
        #
        # - apache2-ab234098245908ddf324a
        # - apache2-295387a9823745feff239
        # - mysql-1a2b9e1298734dfe90444
        #
        class CookbookArtifactsDir < CookbooksDir

          def make_child_entry(name)
            result = @children.find { |child| child.name == name } if @children
            result || CookbookArtifactDir.new(name, self)
          end

          def children
            @children ||= begin
              result = []
              root.get_json("#{api_path}/?num_versions=all").each_pair do |cookbook_name, cookbooks|
                cookbooks["versions"].each do |cookbook_version|
                  result << CookbookArtifactDir.new("#{cookbook_name}-#{cookbook_version['identifier']}", self)
                end
              end
              result.sort_by(&:name)
            end
          end

          # Knife currently does not understand versioned cookbooks
          # Cookbook Version uploader also requires a lot of refactoring
          # to make this work. So instead, we make a temporary cookbook
          # symlinking back to real cookbook, and upload the proxy.
          def upload_cookbook(other, options)
            cookbook_name, _, identifier = other.name.rpartition("-")

            Dir.mktmpdir do |temp_cookbooks_path|
              proxy_cookbook_path = "#{temp_cookbooks_path}/#{cookbook_name}"

              # Make a symlink
              file_class.symlink other.file_path, proxy_cookbook_path

              # Instantiate a proxy loader using the temporary symlink
              proxy_loader = Chef::Cookbook::CookbookVersionLoader.new(proxy_cookbook_path, other.parent.chefignore)
              proxy_loader.load_cookbooks

              cookbook_to_upload = proxy_loader.cookbook_version
              cookbook_to_upload.identifier = identifier
              cookbook_to_upload.freeze_version if options[:freeze]

              # Instantiate a new uploader based on the proxy loader
              uploader = Chef::CookbookUploader.new(cookbook_to_upload, force: options[:force], rest: chef_rest, policy_mode: true)

              with_actual_cookbooks_dir(temp_cookbooks_path) do
                uploader.upload_cookbooks
              end

              #
              # When the temporary directory is being deleted on
              # windows, the contents of the symlink under that
              # directory is also deleted. So explicitly remove
              # the symlink without removing the original contents if we
              # are running on windows
              #
              if Chef::Platform.windows?
                Dir.rmdir proxy_cookbook_path
              end
            end
          end

          def chef_rest
            Chef::ServerAPI.new(root.chef_rest.url, root.chef_rest.options.merge(version_class: Chef::CookbookManifestVersions))
          end

          def can_have_child?(name, is_dir)
            is_dir && name.include?("-")
          end
        end
      end
    end
  end
end
