#
#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

        if config[:all] 
          cl = Chef::CookbookLoader.new
          cl.each do |cookbook|
            Chef::Log.info("** #{cookbook.name.to_s} **")
            upload_cookbook(cookbook.name.to_s)
          end
        else
          @name_args.each do |cb|
            Chef::Log.info("** #{cb} **")
            upload_cookbook(cb)
          end
        end
      end
      
      def test_ruby(cookbook_dir)
        Dir[File.join(cookbook_dir, '**', '*.rb')].each do |ruby_file|
          Chef::Log.info("Testing #{ruby_file} for syntax errors...")
          Chef::Mixin::Command.run_command(:command => "ruby -c #{ruby_file}")
        end
      end
      
      def test_templates(cookbook_dir)
        Dir[File.join(cookbook_dir, '**', '*.erb')].each do |erb_file|
          Chef::Log.info("Testing template #{erb_file} for syntax errors...")
          Chef::Mixin::Command.run_command(:command => "sh -c 'erubis -x #{erb_file} | ruby -c'")
        end
      end

      def upload_cookbook(cookbook_name)

        if cookbook_name =~ /^#{File::SEPARATOR}/
          child_folders = cookbook_name 
          cookbook_name = File.basename(cookbook_name)
        else
          child_folders = config[:cookbook_path].inject([]) do |r, e| 
            r << File.join(e, cookbook_name)
            r
          end
        end

        tmp_cookbook_tarball = Tempfile.new("chef-#{cookbook_name}")
        tmp_cookbook_tarball.close
        tarball_name = "#{tmp_cookbook_tarball.path}.tar.gz"
        File.unlink(tmp_cookbook_tarball.path)

        tmp_cookbook_path = Tempfile.new("chef-#{cookbook_name}-build")
        tmp_cookbook_path.close
        tmp_cookbook_dir = tmp_cookbook_path.path
        File.unlink(tmp_cookbook_dir)
        FileUtils.mkdir_p(tmp_cookbook_dir)

        Chef::Log.debug("Staging at #{tmp_cookbook_dir}")

        found_cookbook = false 

        child_folders.each do |file_path|
          if File.directory?(file_path)
            found_cookbook = true 
            Chef::Log.info("Copying from #{file_path} to #{tmp_cookbook_dir}")
            FileUtils.cp_r(file_path, tmp_cookbook_dir, :remove_destination => true)
          else
            Chef::Log.info("Nothing to copy from #{file_path}")
          end
        end 

        unless found_cookbook
          Chef::Log.fatal("Could not find cookbook #{cookbook_name}!")
          exit 17
        end

        test_ruby(tmp_cookbook_dir)
        test_templates(tmp_cookbook_dir)

        # First, generate metadata
        kcm = Chef::Knife::CookbookMetadata.new
        kcm.config[:cookbook_path] = [ tmp_cookbook_dir ]
        kcm.name_args = [ cookbook_name ]
        kcm.run

        Chef::Log.info("Creating tarball at #{tarball_name}")
        Chef::Mixin::Command.run_command(
          :command => "tar -C #{tmp_cookbook_dir} -cvzf #{tarball_name} ./#{cookbook_name}"
        )

        begin
          cb = rest.get_rest("cookbooks/#{cookbook_name}")
          cookbook_uploaded = true
        rescue Net::HTTPServerException => e
          case e.response.code
          when "404"
            cookbook_uploaded = false
          when "401"
            Chef::Log.fatal "Failed to fetch remote cookbook '#{cookbook_name}' due to authentication failure (#{e}), check your client configuration (username, key)"
            exit 18
          end
        end

        if cookbook_uploaded
          Chef::StreamingCookbookUploader.put(
            "#{Chef::Config[:chef_server_url]}/cookbooks/#{cookbook_name}/_content", 
            Chef::Config[:node_name], 
            Chef::Config[:client_key], 
            {
              :file => File.new(tarball_name), 
              :name => cookbook_name
            }
          )
        else
          Chef::StreamingCookbookUploader.post(
            "#{Chef::Config[:chef_server_url]}/cookbooks", 
            Chef::Config[:node_name], 
            Chef::Config[:client_key], 
            {
              :file => File.new(tarball_name), 
              :name => cookbook_name
            }
          )
        end
        Chef::Log.info("Upload complete!")
        Chef::Log.debug("Removing local tarball at #{tarball_name}")
        FileUtils.rm_rf tarball_name 
        Chef::Log.debug("Removing local staging directory at #{tmp_cookbook_dir}")
        FileUtils.rm_rf tmp_cookbook_dir
      end
      
    end
  end
end







