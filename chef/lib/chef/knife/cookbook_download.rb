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

class Chef
  class Knife
    class CookbookDownload < Knife

      banner "Sub-Command: cookbook download COOKBOOK VERSION (options)"

      option :version,
       :short => "-v VERSION",
       :long => "--version VERSION",
       :description => "The version of the cookbook to download"

      option :download_directory,
       :short => "-d DOWNLOAD_DIRECTORY",
       :long => "--dir DOWNLOAD_DIRECTORY",
       :description => "The directory to download the cookbook into",
       :default => Dir.pwd
      
      option :force,
       :short => "-f",
       :long => "--force",
       :description => "Force download over the download directory if it exists"

      # TODO: tim/cw: 5-23-2010: need to implement knife-side
      # specificity for downloads - need to implement --platform and
      # --fqdn here
      def run
        if @name_args.length != 2
          Chef::Log.fatal("You must supply a cookbook name and version to download!")
          exit 42
        end
          
        cookbook_name = @name_args[0]
        cookbook_version = @name_args[1] == 'latest' ? '_latest' : @name_args[1]
        Chef::Log.info("Downloading #{cookbook_name} cookbook version #{cookbook_version}")
        
        cookbook = rest.get_rest("cookbooks/#{cookbook_name}/#{cookbook_version}")
        manifest = cookbook.manifest

        basedir = File.join(config[:download_directory], "#{cookbook_name}-#{cookbook.version}")
        if File.exists?(basedir)
          if config[:force]
            Chef::Log.debug("Deleting #{basedir}")
            FileUtils.rm_rf(basedir)
          else
            Chef::Log.fatal("Directory #{basedir} exists, use --force to overwrite")
            exit
          end
        end
        
        Chef::CookbookVersion::COOKBOOK_SEGMENTS.each do |segment|
          next unless manifest.has_key?(segment)
          Chef::Log.info("Downloading #{segment}")
          manifest[segment].each do |segment_file|
            dest = File.join(basedir, segment_file['path'].gsub('/', File::SEPARATOR))
            Chef::Log.debug("Downloading #{segment_file['path']} to #{dest}")
            FileUtils.mkdir_p(File.dirname(dest))
            rest.sign_on_redirect = false
            tempfile = rest.get_rest(segment_file['uri'], true)
            FileUtils.mv(tempfile.path, dest)
          end
        end
        Chef::Log.info("Cookbook downloaded to #{basedir}")
      end

    end
  end
end
