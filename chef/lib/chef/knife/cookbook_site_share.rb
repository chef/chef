# Author:: Nuo Yan (<nuo@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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
    class CookbookSiteShare < Knife

      banner "knife cookbook site share COOKBOOK CATEGORY (options)"
            
      option :cookbook_path,
        :short => "-o PATH:PATH",
        :long => "--cookbook-path PATH:PATH",
        :description => "A colon-separated path to look for cookbooks in",
        :proc => lambda { |o| o.split(":") }

      def run
        if config[:cookbook_path]
          Chef::Config[:cookbook_path] = config[:cookbook_path]
        else
          config[:cookbook_path] = Chef::Config[:cookbook_path]
        end
        
        if @name_args.length < 2
          show_usage
          Chef::Log.fatal("You must specify the cookbook name and the category you want to share this cookbook to.")
          exit 1
        end
        
        
        cl = Chef::CookbookLoader.new
        if cl.cookbook_exists?(@name_args[0])
          Chef::Mixin::Command.run_command(:command => "tar -cvzf #{@name_args[0]}.tgz #{@name_args[0]}", :cwd => config[:cookbook])
          
          
          do_upload()
        else
          Chef::Log.error("Could not find cookbook #{@name_args[0]} in your cookbook path, skipping it")
        end

      end
      
      def do_upload(cookbook_filename, cookbook_category, user_id, user_secret_filename)
         cookbook_uploader = Chef::CookbookSiteStreamingUploader.new
         uri = make_uri "api/v1/cookbooks"

         category_string = { 'category'=>cookbook_category }.to_json

         http_resp = cookbook_uploader.post(uri, user_id, user_secret_filename, {
           :tarball => File.open(cookbook_filename),
           :cookbook => category_string
         })

         res = JSON.parse(http_resp.body)
         if http_resp.code.to_i != 201
           if !res['error_messages'].nil?
             if res['error_messages'][0] =~ /Version already exists/
               raise "Version already exists"
             else
               raise Exception, res
             end
           else
             raise Exception, "Error uploading: #{res}"
           end
         end
         res
       end
      
      
    end
  end
end





