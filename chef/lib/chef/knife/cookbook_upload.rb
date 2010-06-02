#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2009, 2010 Opscode, Inc.
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

require 'chef/knife'
require 'chef/streaming_cookbook_uploader'
require 'chef/cache/checksum'
require 'chef/sandbox'
require 'chef/cookbook'
require 'chef/cookbook/file_system_file_vendor'
require 'opscode/rest'

class Chef
  class Knife
    class CookbookUpload < Knife

      banner "Sub-Command: cookbook upload [COOKBOOKS...] (options)"

      option :cookbook_path,
        :short => "-o PATH:PATH",
        :long => "--cookbook-path PATH:PATH",
        :description => "A colon-separated path to look for cookbooks in",
        :proc => lambda { |o| o.split(":") }

      option :all,
        :short => "-a",
        :long => "--all",
        :description => "Upload all cookbooks, rather than just a single cookbook"

      def run 
        if config[:cookbook_path]
          Chef::Config[:cookbook_path] = config[:cookbook_path]
        else
          config[:cookbook_path] = Chef::Config[:cookbook_path]
        end

        Chef::Cookbook::FileVendor.on_create { |manifest| Chef::Cookbook::FileSystemFileVendor.new(manifest) }

        cl = Chef::CookbookLoader.new
        if config[:all]
          cl.each do |cookbook_name, cookbook|
            Chef::Log.info("** #{cookbook.name.to_s} **")
            upload_cookbook(cookbook)
          end
        else
          @name_args.each{|cookbook_name| upload_cookbook(cl[cookbook_name]) }
        end
      end
      
      def test_ruby(cookbook_dir)
        Chef::Log.info("Validating ruby files")
        Dir[File.join(cookbook_dir, '**', '*.rb')].each do |ruby_file|
          Chef::Log.info("Testing #{ruby_file} for syntax errors...")
          Chef::Mixin::Command.run_command(:command => "ruby -c #{ruby_file}")
        end
      end
      
      def test_templates(cookbook_dir)
        Chef::Log.info("Validating templates")
        Dir[File.join(cookbook_dir, '**', '*.erb')].each do |erb_file|
          Chef::Log.info("Testing template #{erb_file} for syntax errors...")
          Chef::Mixin::Command.run_command(:command => "sh -c 'erubis -x #{erb_file} | ruby -c'")
        end
      end
      
      def upload_cookbook(cookbook)
        Chef::Log.info("Saving #{cookbook.name}")
        
        # create build directory
        tmp_cookbook_dir = create_build_dir(cookbook)

        # create a CookbookLoader that loads a Cookbook from the build directory
        orig_cookbook_path = nil
        build_dir_cookbook = nil
        begin
          orig_cookbook_path = Chef::Config.cookbook_path
          Chef::Config.cookbook_path = tmp_cookbook_dir
          build_dir_cookbook = Chef::CookbookLoader.new[cookbook.name]
          Chef::Log.debug("Staged cookbook manifest:\n#{JSON.pretty_generate(build_dir_cookbook)}")
        ensure
          Chef::Config.cookbook_path = orig_cookbook_path
        end

        # generate checksums of cookbook files and create a sandbox
        checksum_files = build_dir_cookbook.checksums
        checksums = checksum_files.inject({}){|memo,elt| memo[elt.first]=nil ; memo}
        new_sandbox = catch_auth_exceptions{ rest.post_rest("/sandboxes", { :checksums => checksums }) }
        
        # upload the new checksums and commit the sandbox
        new_sandbox['checksums'].each do |checksum, info|
          if info['needs_upload'] == true
            Chef::Log.debug("PUTting #{checksum_files[checksum]} (checksum hex = #{checksum}) to #{info['url']}")
            # TODO - 5/28/2010, cw: make this a streaming request
            # checksum is the hexadecimal representation of the md5,
            # but we need the base64-encoding for the content-md5
            # header
            checksum64 = Base64.encode64([checksum].pack("H*")).strip
            headers = { 'content-type'=>'application/x-binary', 'content-md5' => checksum64 }
            options = {
              :authenticate => true,
              :user_secret  => OpenSSL::PKey::RSA.new(rest.signing_key),
              :user_id      => rest.client_name,
              :headers      => headers,
              :payload      => File.read(checksum_files[checksum])
            }
            begin
              Opscode::REST.new.request(:put, info['url'], options)
            rescue RestClient::RequestFailed => e
              Chef::Log.error("Upload failed: #{e.message}\n#{e.response.body}")
              raise
            end
          end
        end
        sandbox_url = new_sandbox['uri']
        Chef::Log.debug("Committing sandbox")
        catch_auth_exceptions{ rest.put_rest(sandbox_url, {:is_completed => true}) }

        # files are uploaded, so save the manifest
        catch_auth_exceptions{ build_dir_cookbook.save }
        
        Chef::Log.info("Upload complete!")
        Chef::Log.debug("Removing local staging directory at #{tmp_cookbook_dir}")
        FileUtils.rm_rf tmp_cookbook_dir
      end

      def create_build_dir(cookbook)
        tmp_cookbook_path = Tempfile.new("chef-#{cookbook.name}-build")
        tmp_cookbook_path.close
        tmp_cookbook_dir = tmp_cookbook_path.path
        File.unlink(tmp_cookbook_dir)
        FileUtils.mkdir_p(tmp_cookbook_dir)
        
        Chef::Log.debug("Staging at #{tmp_cookbook_dir}")

        checksums_to_on_disk_paths = cookbook.checksums

        Chef::Cookbook::COOKBOOK_SEGMENTS.each do |segment|
          cookbook.manifest[segment].each do |manifest_record|
            path_in_cookbook = manifest_record[:path]
            on_disk_path = checksums_to_on_disk_paths[manifest_record[:checksum]]
            dest = File.join(tmp_cookbook_dir, cookbook.name.to_s, path_in_cookbook)
            FileUtils.mkdir_p(File.dirname(dest))
            FileUtils.cp(on_disk_path, dest)
          end
        end
        
        # Validate ruby files and templates
        test_ruby(tmp_cookbook_dir)
        test_templates(tmp_cookbook_dir)

        # First, generate metadata
        Chef::Log.debug("Generating metadata")
        kcm = Chef::Knife::CookbookMetadata.new
        kcm.config[:cookbook_path] = [ tmp_cookbook_dir ]
        kcm.name_args = [ cookbook.name.to_s ]
        kcm.run
      end

      def catch_auth_exceptions
        begin
          yield
        rescue Net::HTTPServerException => e
          case e.response.code
          when "401"
            Chef::Log.fatal "Request failed due to authentication (#{e}), check your client configuration (username, key)"
            exit 18
          end
        end
      end
      
    end
  end
end







