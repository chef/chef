#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
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

require File.join(File.dirname(__FILE__), "file")
require 'uri'
require 'tempfile'
require 'net/https'

class Chef
  class Provider
    class RemoteFile < Chef::Provider::File
      
      def action_create        
        Chef::Log.debug("Checking #{@new_resource} for changes")
        do_remote_file(@new_resource.source, @current_resource.path)
      end
    
      def do_remote_file(source, path)
        r = Chef::REST.new(Chef::Config[:remotefile_url])
      
        current_checksum = nil
        current_checksum = self.checksum(path) if ::File.exists?(path)

        url = generate_url(
          source, 
          "files", 
          { 
            :checksum => current_checksum
          }
        )

        raw_file = nil
        begin
          raw_file = r.get_rest(url, true)
        rescue Net::HTTPRetriableError => e
          if e.to_s =~ /304 "Not Modified"/ 
            Chef::Log.debug("File #{path} is unchanged")
            return
          else
            raise e
          end
        end
      
        update = false
        if ::File.exists?(path)
          raw_file_checksum = self.checksum(raw_file.path)
        
          if raw_file_checksum != current_checksum
            Chef::Log.debug("#{path} changed from #{current_checksum} to #{raw_file_checksum}")
            Chef::Log.info("Updating file for #{@new_resource} at #{path}")          
            update = true
          end
        else
          Chef::Log.info("Creating file for #{@new_resource} at #{path}")
          update = true
        end

        if update
          backup(path)
          FileUtils.cp(raw_file.path, path)
          @new_resource.updated = true
        end

        set_owner if @new_resource.owner != nil
        set_group if @new_resource.group != nil
        set_mode if @new_resource.mode != nil
      end
      
    end
  end
end