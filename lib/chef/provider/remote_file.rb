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
require 'rest_client'
require 'uri'
require 'tempfile'
require 'net/https'
require 'net/ftp'

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
            uri = URI.parse(source)
            if URI::HTTP === uri
              #HTTP or HTTPS
              raw_file = RestClient::Request.execute(:method => :get, :url => source, :raw_response => true).file
            else
              #FTP
              raw_file = ftp_fetch(uri)
            end
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

      private

      def ftp_fetch(uri)
        # Shamelessly stolen from open-uri
        # Fetches the file using Net::FTP, returning a Tempfile
        path = uri.path
        path = path.sub(%r{\A/}, '%2F') # re-encode the beginning slash because uri library decodes it.
        directories = path.split(%r{/}, -1)
        directories.each {|d|
          d.gsub!(/%([0-9A-Fa-f][0-9A-Fa-f])/) { [$1].pack("H2") }
        }
        unless filename = directories.pop
          raise ArgumentError, "no filename: #{uri.inspect}"
        end
        directories.each {|d|
          if /[\r\n]/ =~ d
            raise ArgumentError, "invalid directory: #{d.inspect}"
          end
        }
        if /[\r\n]/ =~ filename
          raise ArgumentError, "invalid filename: #{filename.inspect}"
        end 
        typecode = uri.typecode
        if typecode && /\A[aid]\z/ !~ typecode
          raise ArgumentError, "invalid typecode: #{typecode.inspect}"
        end

        tempfile = Tempfile.new(filename)

        # The access sequence is defined by RFC 1738
        ftp = Net::FTP.new
        ftp.connect(uri.hostname, uri.port)
        ftp.passive = true if !@new_resource.ftp_active_mode
        # todo: extract user/passwd from .netrc.
        user = 'anonymous'
        passwd = nil
        user, passwd = uri.userinfo.split(/:/) if uri.userinfo
        ftp.login(user, passwd)
        directories.each {|cwd|
          ftp.voidcmd("CWD #{cwd}")
        }
        if typecode
          # xxx: typecode D is not handled.
          ftp.voidcmd("TYPE #{typecode.upcase}")
        end
        ftp.getbinaryfile(filename, tempfile.path)
        ftp.close

        tempfile
      end
    end
  end
end
