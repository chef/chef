#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Jesse Campbell (<hikeit@gmail.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'chef/provider/file'
require 'rest_client'
require 'chef/provider/remote_file/ftp'
require 'uri'
require 'tempfile'

class Chef
  class Provider
    class RemoteFile < Chef::Provider::File

      def load_current_resource
        @current_resource = Chef::Resource::RemoteFile.new(@new_resource.name)
        super
      end

      def action_create
        Chef::Log.debug("#{@new_resource} checking for changes")

        if current_resource_matches_target_checksum?
          Chef::Log.debug("#{@new_resource} checksum matches target checksum (#{@new_resource.checksum}) - not updating")
        else
          uri = URI.parse(@new_resource.source)
          if URI::HTTP === uri
            #HTTP or HTTPS
            raw_file = RestClient::Request.execute(:method => :get, :url => @new_resource.source, :raw_response => true).file
          elsif URI::FTP === uri
            #FTP
            raw_file = FTP::fetch(uri, @new_resource.ftp_active_mode)
          else
            raise "Invalid uri. Only http(s) and ftp are currently supported"
          end
          if matches_current_checksum?(raw_file)
            Chef::Log.debug "#{@new_resource} target and source checksums are the same - not updating"
          else
            description = [] 
            description << "copy file downloaded from #{@new_resource.source} into #{@new_resource.path}"
            description << diff_current(raw_file.path)
            converge_by(description) do
              backup_new_resource
              FileUtils.cp raw_file.path, @new_resource.path
              Chef::Log.info "#{@new_resource} updated"
              raw_file.close!
            end
            # whyrun mode cleanup - the temp file will never be used,
            # so close/unlink it here. 
            if whyrun_mode?
              raw_file.close!
            end
          end
        end
        set_all_access_controls
      end

      def current_resource_matches_target_checksum?
        @new_resource.checksum && @current_resource.checksum && @current_resource.checksum =~ /^#{Regexp.escape(@new_resource.checksum)}/
      end

      def matches_current_checksum?(candidate_file)
        Chef::Log.debug "#{@new_resource} checking for file existence of #{@new_resource.path}"
        if ::File.exists?(@new_resource.path)
          Chef::Log.debug "#{@new_resource} file exists at #{@new_resource.path}"
          @new_resource.checksum(checksum(candidate_file.path))
          Chef::Log.debug "#{@new_resource} target checksum: #{@current_resource.checksum}"
          Chef::Log.debug "#{@new_resource} source checksum: #{@new_resource.checksum}"

          @new_resource.checksum == @current_resource.checksum
        else
          Chef::Log.debug "#{@new_resource} creating #{@new_resource.path}"
          false
        end
      end

      def backup_new_resource
        if ::File.exists?(@new_resource.path)
          Chef::Log.debug "#{@new_resource} checksum changed from #{@current_resource.checksum} to #{@new_resource.checksum}"
          backup @new_resource.path
        end
      end
    end
  end
end
