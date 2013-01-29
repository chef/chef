#
# Author:: Adam Jacob (<adam@opscode.com>)
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
require 'chef/rest'
require 'uri'
require 'tempfile'
require 'net/https'

class Chef
  class Provider
    class RemoteFile < Chef::Provider::File

      include Chef::Mixin::EnforceOwnershipAndPermissions

      def load_current_resource
        @current_resource = Chef::Resource::RemoteFile.new(@new_resource.name)
        super
      end

      def action_create
        Chef::Log.debug("#{@new_resource} checking for changes")

        if current_resource_matches_target_checksum?
          Chef::Log.debug("#{@new_resource} checksum matches target checksum (#{@new_resource.checksum}) - not updating")
        else
          sources = @new_resource.source
          source = sources.shift
          begin
            rest = Chef::REST.new(source, nil, nil, http_client_opts(source))
            raw_file = rest.streaming_request(rest.create_url(source), {})
          rescue SocketError, Errno::ECONNREFUSED, Timeout::Error, Net::HTTPFatalError => e
            Chef::Log.debug("#{@new_resource} cannot be downloaded from #{source}")
            if source = sources.shift
              Chef::Log.debug("#{@new_resource} trying to download from another mirror")
              retry
            else
              raise e
            end
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
        update_new_file_state
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

      def source_file(source, current_checksum, &block)
        if absolute_uri?(source)
          fetch_from_uri(source, &block)
        elsif !Chef::Config[:solo]
          fetch_from_chef_server(source, current_checksum, &block)
        else
          fetch_from_local_cookbook(source, &block)
        end
      end

      def http_client_opts(source)
        opts={}
        # CHEF-3140
        # 1. If it's already compressed, trying to compress it more will
        # probably be counter-productive.
        # 2. Some servers are misconfigured so that you GET $URL/file.tgz but
        # they respond with content type of tar and content encoding of gzip,
        # which tricks Chef::REST into decompressing the response body. In this
        # case you'd end up with a tar archive (no gzip) named, e.g., foo.tgz,
        # which is not what you wanted.
        if @new_resource.path =~ /gz$/ or source =~ /gz$/
          opts[:disable_gzip] = true
        end
        opts
      end

      private

      def absolute_uri?(source)
        URI.parse(source).absolute?
      rescue URI::InvalidURIError
        false
      end

    end
  end
end
