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
          cl.each do |cookbook|
            Chef::Log.info("** #{cookbook.name.to_s} **")
            upload_cookbook(cookbook.name.to_s)
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
        
        # create build directory and create a CookbookLoader that points to it
        tmp_cookbook_dir = create_build_dir(cookbook)
        
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
        
        # upload the new checksums and finalize the sandbox
        new_sandbox['checksums'].each do |checksum, info|
          if info['needs_upload'] == true
            Chef::Log.debug("PUTting file with checksum #{checksum} to #{info['url']}")
            put_res = Chef::StreamingCookbookUploader.put(
                                                          info['url'],
                                                          rest.client_name,
                                                          rest.signing_key_filename,
                                                          {
                                                            :file => File.new(checksum_files[checksum]),
                                                            :name => checksum
                                                          }
                                                          )
            Chef::Log.debug("#{JSON.parse(put_res.body).inspect}")
          end
        end
        sandbox_url = new_sandbox['uri']
        Chef::Log.debug("Finalizing sandbox")
        finalize_res = catch_auth_exceptions{ rest.put_rest(sandbox_url, {:is_completed => true}) }

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
          cookbook.manifest[segment].each do |segment_file|
            path_in_cookbook = segment_file[:path]
            on_disk_path = checksums_to_on_disk_paths[segment_file[:checksum]]
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







