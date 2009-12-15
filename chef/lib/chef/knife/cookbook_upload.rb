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

class Chef
  class Knife
    class CookbookUpload < Knife

      banner "Sub-Command: cookbook upload COOKBOOK (options)"

      option :cookbook_path,
        :short => "-o PATH:PATH",
        :long => "--cookbook-path PATH:PATH",
        :description => "A colon-separated path to look for cookbooks in",
        :proc => lambda { |o| o.split(":") }

      def run 

        config[:cookbook_path] ||= Chef::Config[:cookbook_path]

        cookbook_name = @name_args[0]
        if cookbook_name =~ /^#{File::SEPARATOR}/
          child_folders = cookbook_name 
          cookbook_name = File.basename(cookbook_name)
        else
          child_folders = config[:cookbook_path].reverse.inject([]) do |r, e| 
            r << File.join(e, @name_args[0])
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
            FileUtils.cp_r(file_path, tmp_cookbook_dir)
          else
            Chef::Log.info("Nothing to copy from #{file_path}")
          end
        end 

        unless found_cookbook
          Chef::Log.fatal("Could not find cookbook #{cookbook_name}!")
          exit 17
        end

        Chef::Log.info("Creating tarball at #{tarball_name}")
        Chef::Mixin::Command.run_command(
          :command => "tar -C #{tmp_cookbook_dir} -cvzf #{tarball_name} ./#{cookbook_name}"
        )

        begin
          cb = rest.get_rest("cookbooks/#{cookbook_name}")
          cookbook_uploaded = true
        rescue Net::HTTPServerException
          cookbook_uploaded = false
        end
        Chef::Log.info("Uploading #{cookbook_name} (#{cookbook_uploaded ? 'new version' : 'first time'})")
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







