#
# Author:: Jesse Campbell (<hikeit@gmail.com>)
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
require 'rest_client'
require 'uri'
require 'tempfile'

class Chef
  class Provider
    class RemoteFile < Chef::Provider::File

      include Chef::Mixin::EnforceOwnershipAndPermissions

      def load_current_resource
        @current_resource = Chef::Resource::RemoteFile.new(@new_resource.name)
        fileinfo = load_fileinfo
        if fileinfo["src"]
          @current_resource.etag fileinfo["etag"]
          @current_resource.last_modified fileinfo["last_modified"]
          @current_resource.source fileinfo["src"]
        end
        super
      end

      def action_create
        Chef::Log.debug("#{@new_resource} checking for changes")

        if current_resource_matches_target_checksum?
          Chef::Log.debug("#{@new_resource} checksum matches target checksum (#{@new_resource.checksum}) - not updating")
        else
          sources = @new_resource.source
          raw_file, raw_file_source, target_matched = try_multiple_sources(sources)
          if target_matched
            Chef::Log.info("#{@new_resource} matched #{raw_file_source}, not updating")
          elsif matches_current_checksum?(raw_file)
            Chef::Log.info("#{@new_resource} downloaded from #{raw_file_source}, checksums match, not updating")
          else
            Chef::Log.info("#{@new_resource} downloaded from #{raw_file_source}")
            description = [] 
            description << "copy file downloaded from #{raw_file_source} into #{@new_resource.path}"
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

      private

      # Given an array of source uris, iterate through them until one does not fail
      def try_multiple_sources(sources)
        sources = sources.dup
        source = sources.shift
        begin
          uri = URI.parse(source)
          raw_file, target_matched = grab_file_from_uri(uri)
        rescue ArgumentError => e
          raise e
        rescue => e
          if e.is_a?(RestClient::Exception)
            error = "Request returned #{e.message}"
          else
            error = e.to_s
          end
          Chef::Log.info("#{@new_resource} cannot be downloaded from #{source}: #{error}")
          if source = sources.shift
            Chef::Log.info("#{@new_resource} trying to download from another mirror")
            retry
          else
            raise e
          end
        end
        if uri.userinfo
          uri.password = "********"
        end
        return raw_file, uri.to_s, target_matched
      end

      # Given a source uri, return a Tempfile, or a File that acts like a Tempfile (close! method)
      def grab_file_from_uri(uri)
        if_modified_since = @new_resource.last_modified
        if_none_match = @new_resource.etag
        if uri == @current_resource.source[0]
          if_modified_since ||= @current_resource.last_modified
          if_none_match ||= @current_resource.etag
        end
        if URI::HTTP === uri
          #HTTP or HTTPS
          raw_file, last_modified, etag, target_matched = http_fetch(uri, if_modified_since, if_none_match)
        elsif URI::FTP === uri
          #FTP
          raw_file, last_modified = FTP::fetch_if_modified(uri, @new_resource.ftp_active_mode, if_modified_since)
          etag = nil
          target_matched = last_modified && if_modified_since && last_modified.to_i <= if_modified_since.to_i
        elsif uri.scheme == "file"
          #local/network file
          last_modified = ::File.mtime(uri.path)
          etag = nil
          raw_file = ::File.new(uri.path, "r")
          def raw_file.close!
            self.close
          end
          target_mathed = last_modified && if_modified_since && last_modified.to_i <= if_modified_since.to_i
        else
          raise ArgumentError, "Invalid uri. Only http(s), ftp, and file are currently supported"
        end
        unless target_matched
          @new_resource.etag etag unless @new_resource.etag
          @new_resource.last_modified last_modified unless @new_resource.last_modified
          save_fileinfo(uri)
        end
        return raw_file, target_matched
      end

      def http_fetch(uri, if_modified_since, if_none_match)
        last_modified = nil
        etag = nil
        target_matched = false
        begin
          headers = Hash.new
          if if_none_match
            headers[:if_none_match] = "\"#{if_none_match}\""
          elsif if_modified_since
            headers[:if_modified_since] = if_modified_since.strftime("%a, %d %b %Y %H:%M:%S %Z")
          end
          rest = RestClient::Request.execute(:method => :get, :url => uri.to_s, :headers => headers, :raw_response => true)
          raw_file = rest.file
          if rest.headers.include?(:last_modified)
            last_modified = Time.parse(rest.headers[:last_modified])
          end
          if rest.headers.include?(:etag)
            etag = rest.headers[:etag]
          end
        rescue RestClient::Exception => e
          if e.http_code == 304
            target_matched = true
          else
            raise e
          end
        end
        return raw_file, last_modified, etag, target_matched
      end

      def load_fileinfo
        begin
          Chef::JSONCompat.from_json(Chef::FileCache.load("remote_file/#{new_resource.name}"))
        rescue Chef::Exceptions::FileNotFound
          cache = Hash.new
          cache["etag"] = nil
          cache["last_modified"] = nil
          cache["src"] = nil
          cache
        end
      end

      def save_fileinfo(uri)
        cache = Hash.new
        cache["etag"] = @new_resource.etag
        cache["last_modified"] = @new_resource.last_modified
        cache["src"] = uri
        Chef::FileCache.store("remote_file/#{new_resource.name}", cache.to_json)
      end
    end
  end
end
