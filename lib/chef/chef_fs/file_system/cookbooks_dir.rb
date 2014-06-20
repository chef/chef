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

require 'chef/chef_fs/parallelizer'
require 'chef/chef_fs/file_system/rest_list_dir'
require 'chef/chef_fs/file_system/cookbook_dir'
require 'chef/chef_fs/file_system/operation_failed_error'
require 'chef/chef_fs/file_system/cookbook_frozen_error'
require 'chef/chef_fs/file_system/chef_repository_file_system_cookbook_dir'
require 'chef/mixin/file_class'

require 'tmpdir'

class Chef
  module ChefFS
    module FileSystem
      class CookbooksDir < RestListDir

        include Chef::Mixin::FileClass

        def initialize(parent)
          super("cookbooks", parent)
        end

        def child(name)
          if @children
            result = self.children.select { |child| child.name == name }.first
            if result
              result
            else
              NonexistentFSObject.new(name, self)
            end
          else
            CookbookDir.new(name, self)
          end
        end

        def children
          @children ||= begin
            if Chef::Config[:versioned_cookbooks]
              result = []
              root.get_json("#{api_path}/?num_versions=all").each_pair do |cookbook_name, cookbooks|
                cookbooks['versions'].each do |cookbook_version|
                  result << CookbookDir.new("#{cookbook_name}-#{cookbook_version['version']}", self, :exists => true)
                end
              end
            else
              result = root.get_json(api_path).keys.map { |cookbook_name| CookbookDir.new(cookbook_name, self, :exists => true) }
            end
            result.sort_by(&:name)
          end
        end

        def create_child_from(other, options = {})
          @children = nil
          upload_cookbook_from(other, options)
        end

        def upload_cookbook_from(other, options = {})
          case other
          when Chef::ChefFS::FileSystem::CookbookDir
            streaming_upload_from(other, options)
          when Chef::ChefFS::FileSystem::ChefRepositoryFileSystemCookbookDir
            Chef::Config[:versioned_cookbooks] ? upload_versioned_cookbook(other, options) : upload_unversioned_cookbook(other, options)
          end
        rescue Timeout::Error => e
          raise Chef::ChefFS::FileSystem::OperationFailedError.new(:write, self, e), "Timeout writing: #{e}"
        rescue Net::HTTPServerException => e
          case e.response.code
          when "409"
            raise Chef::ChefFS::FileSystem::CookbookFrozenError.new(:write, self, e), "Cookbook #{other.name} is frozen"
          else
            raise Chef::ChefFS::FileSystem::OperationFailedError.new(:write, self, e), "HTTP error writing: #{e}"
          end
        rescue Chef::Exceptions::CookbookFrozen => e
          raise Chef::ChefFS::FileSystem::CookbookFrozenError.new(:write, self, e), "Cookbook #{other.name} is frozen"
        end

        def streaming_upload_from(other, options = {})
          new_sandbox = root.chef_rest.post("sandboxes", {:checksums => other.chef_object.checksums})
          Chef::ChefFS::Parallelizer.parallelize(new_sandbox['checksums']) do |checksum, info|
            if info['needs_upload']
              url = other.chef_object.url_for_checksum(checksum)
              tmpfile = other.root.chef_rest.get_rest(url, true)
              upload_checksum(checksum, info['url'], tmpfile)
              ::File.unlink(tmpfile)
            end
          end.to_a
          root.chef_rest.put_rest(new_sandbox['uri'], {:is_completed => true})
          root.chef_rest.put_rest(other.chef_object.save_url, other.chef_object)
        end

        def upload_checksum(checksum, url, file_path)
          checksum64 = Base64.encode64([checksum].pack("H*")).strip
          timestamp = Time.now.utc.iso8601
          file_contents = File.open(file_path) {|f| f.read}
          headers = { 'content-type' => 'application/x-binary', 'content-md5' => checksum64, "accept" => 'application/json' }
          if root.chef_rest.signing_key
            sign_obj = Mixlib::Authentication::SignedHeaderAuth.signing_object(:http_method => :put,
                                                                               :path        => URI.parse(url).path,
                                                                               :body        => file_contents,
                                                                               :timestamp   => timestamp,
                                                                               :user_id     => root.chef_rest.client_name)
            headers.merge!(sign_obj.sign(OpenSSL::PKey::RSA.new(root.chef_rest.signing_key)))
          end
          Chef::HTTP::Simple.new(url, :headers=>headers).put(url, file_contents)
        end

        # Knife currently does not understand versioned cookbooks
        # Cookbook Version uploader also requires a lot of refactoring
        # to make this work. So instead, we make a temporary cookbook
        # symlinking back to real cookbook, and upload the proxy.
        def upload_versioned_cookbook(other, options)
          cookbook_name = Chef::ChefFS::FileSystem::ChefRepositoryFileSystemCookbookDir.canonical_cookbook_name(other.name)

          Dir.mktmpdir do |temp_cookbooks_path|
            proxy_cookbook_path = "#{temp_cookbooks_path}/#{cookbook_name}"

            # Make a symlink
            file_class.symlink other.file_path, proxy_cookbook_path

            # Instantiate a proxy loader using the temporary symlink
            proxy_loader = Chef::Cookbook::CookbookVersionLoader.new(proxy_cookbook_path, other.parent.chefignore)
            proxy_loader.load_cookbooks

            cookbook_to_upload = proxy_loader.cookbook_version
            cookbook_to_upload.freeze_version if options[:freeze]

            # Instantiate a new uploader based on the proxy loader
            uploader = Chef::CookbookUploader.new(cookbook_to_upload, proxy_cookbook_path, :force => options[:force], :rest => root.chef_rest)

            with_actual_cookbooks_dir(temp_cookbooks_path) do
              upload_cookbook!(uploader)
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

        def upload_unversioned_cookbook(other, options)
          cookbook_to_upload = other.chef_object
          cookbook_to_upload.freeze_version if options[:freeze]
          uploader = Chef::CookbookUploader.new(cookbook_to_upload, other.parent.file_path, :force => options[:force], :rest => root.chef_rest)

          with_actual_cookbooks_dir(other.parent.file_path) do
            upload_cookbook!(uploader)
          end
        end

        # Work around the fact that CookbookUploader doesn't understand chef_repo_path (yet)
        def with_actual_cookbooks_dir(actual_cookbook_path)
          old_cookbook_path = Chef::Config.cookbook_path
          Chef::Config.cookbook_path = actual_cookbook_path if !Chef::Config.cookbook_path

          yield
        ensure
          Chef::Config.cookbook_path = old_cookbook_path
        end

        def upload_cookbook!(uploader, options = {})
          if uploader.respond_to?(:upload_cookbook)
            uploader.upload_cookbook
          else
            uploader.upload_cookbooks
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
