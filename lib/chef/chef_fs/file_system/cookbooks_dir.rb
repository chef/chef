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

require 'chef/chef_fs/file_system/rest_list_dir'
require 'chef/chef_fs/file_system/cookbook_dir'

require 'tmpdir'

class Chef
  module ChefFS
    module FileSystem
      class CookbooksDir < RestListDir
        def initialize(parent)
          super("cookbooks", parent)
        end

        def child(name, options = {})
          result = self.children.select { |child| child.name == name }.first if @children || options[:force]
          return result if result
          if Chef::Config[:versioned_cookbooks]
            raise "Cookbook name #{name} not valid: must be name-version" if name !~ Chef::ChefFS::FileSystem::CookbookDir::VALID_VERSIONED_COOKBOOK_NAME
            CookbookDir.new(name, self, :cookbook_name => $1, :version => $2)
          else
            CookbookDir.new(name, self, :cookbook_name => name, :version => '_latest')
          end
        end

        def children
          return @children if @children
          _to_cookbook_dir = if Chef::Config[:versioned_cookbooks]
                               proc do |cookbook_name, value|
                                 value['versions'].map do |cookbook_version|
                                   CookbookDir.new "#{cookbook_name}-#{cookbook_version['version']}", self,
                                     :versions_map  => value,
                                     :version       => cookbook_version['version'],
                                     :cookbook_name => cookbook_name
                                 end
                               end
                             else
                               proc do |cookbook_name, value|
                                 CookbookDir.new(cookbook_name, self, :versions_map => value, :cookbook_name => cookbook_name, :version => '_latest' )
                               end
                             end
          _api_path = if Chef::Config[:versioned_cookbooks]
                        "#{api_path}/?num_versions=all"
                      else
                        api_path
                      end
          @children = rest.get_rest(_api_path).map(&_to_cookbook_dir).flatten.sort_by { |c| c.name }
        end

        def create_child_from(other)
          upload_cookbook_from(other)
        end


        def upload_cookbook_from(other)
          other_cookbook_version = other.chef_object
          # TODO this only works on the file system.  And it can't be broken into
          # pieces.
          begin
            if Chef::Config[:versioned_cookbooks]
              cookbook_name = Chef::ChefFS::FileSystem::ChefRepositoryFileSystemEntry.canonical_cookbook_name(other.name)

              # TODO: Find some better way to express this
              # We want to symlink a cookbook with a non-versioend cookbook name in a temporary
              # directory, and then upload it. This allows us to use Chef 10-stable and 11-stable.
              proxy_cookbook_path = make_proxy_cookbook_dir(cookbook_name, other.file_path )
              proxy_loader = Chef::Cookbook::CookbookVersionLoader.new("#{proxy_cookbook_path}/#{cookbook_name}", other.parent.chefignore)
              proxy_loader.load_cookbooks
              uploader = Chef::CookbookUploader.new(proxy_loader.cookbook_version, proxy_cookbook_path, :rest => rest)
              actual_cookbook_path = proxy_cookbook_path
            else
              uploader = Chef::CookbookUploader.new(other_cookbook_version, other.parent.file_path, :rest => rest)
              actual_cookbook_path = other.parent.file_path
            end
            # Work around the fact that CookbookUploader doesn't understand chef_repo_path (yet)
            old_cookbook_path = Chef::Config.cookbook_path
            Chef::Config.cookbook_path = actual_cookbook_path if !Chef::Config.cookbook_path
            begin
              if uploader.respond_to?(:upload_cookbook)
                uploader.upload_cookbook
              else
                uploader.upload_cookbooks
              end
            ensure
              FileUtils.remove_entry_secure proxy_cookbook_path if Chef::Config[:versioned_cookbooks]
              Chef::Config.cookbook_path = old_cookbook_path
            end
          rescue Net::HTTPServerException => e
            case e.response.code
            when "409"
              ui.error "Version #{other_cookbook_version.version} of cookbook #{other_cookbook_version.name} is frozen. Use --force to override."
              Chef::Log.debug(e)
              raise Exceptions::CookbookFrozen
            else
              raise
            end
          end
        end

        # Knife currently does not understand versioned cookbooks
        # Cookbook Version uploader also requires a lot of refactoring
        # to make this work. So instead, we make a temporary cookbook
        # symlinking back to real cookbook, and upload the proxy.
        #
        # This will create a temporary dir, symlink, and return the temporary
        # dir
        def make_proxy_cookbook_dir(cookbook_name, cookbook_path)
          Dir.mktmpdir.tap do |dir|
            File.symlink cookbook_path, "#{dir}/#{cookbook_name}"
          end
        end

        def can_have_child?(name, is_dir)
          return false if !is_dir
          return false if Chef::Config[:versioned_cookbooks] && name !~ Chef::ChefFS::FileSystem::CookbookDir::VALID_VERSIONED_COOKBOOK_NAME
          return true
        end
      end
    end
  end
end
