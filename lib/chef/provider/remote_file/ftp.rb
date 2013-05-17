#
# Author:: Jesse Campbell (<hikeit@gmail.com>)
# Copyright:: Copyright (c) 2013 Jesse Campbell
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

require 'uri'
require 'tempfile'
require 'net/ftp'
require 'chef/provider/remote_file'
require 'chef/provider/remote_file/util'
require 'chef/provider/remote_file/result'
require 'chef/file_content_management/tempfile'

class Chef
  class Provider
    class RemoteFile
      class FTP

        attr_reader :ftp_active_mode

        def initialize(uri, new_resource, current_resource)
          @new_resource = new_resource
          @ftp_active_mode = new_resource.ftp_active_mode
          @hostname = uri.host
          @port = uri.port
          @directories, @filename = parse_path(uri.path)
          if current_resource.source && Chef::Provider::RemoteFile::Util.uri_matches_string?(uri, current_resource.source[0])
            if current_resource.use_last_modified && current_resource.last_modified
              @last_modified = current_resource.last_modified
            end
          end
          # Only support ascii and binary types
          @typecode = uri.typecode
          if @typecode && /\A[ai]\z/ !~ @typecode
            raise ArgumentError, "invalid typecode: #{@typecode.inspect}"
          end
          if uri.userinfo
            @user = URI.unescape(uri.user)
            @pass = URI.unescape(uri.password)
          else
            @user = 'anonymous'
            @pass = nil
          end
          @uri = uri
        end

        def fetch
          saved_socks_env = ENV['SOCKS_SERVER']
          begin
            ENV['SOCKS_SERVER'] = proxy_uri(@uri).to_s
            connect
            mtime = ftp.mtime(@filename)
            tempfile = if mtime && @last_modified && mtime.to_i <= @last_modified.to_i
                         nil
                       else
                         get
                       end
            disconnect
            @result = Chef::Provider::RemoteFile::Result.new(tempfile, nil, mtime)
          ensure
            ENV['SOCKS_SERVER'] = saved_socks_env
          end
          return @result
        end

        def ftp
          @ftp ||= Net::FTP.new
        end

        private

        def connect
          # The access sequence is defined by RFC 1738
          ftp.connect(@hostname, @port)
          ftp.passive = !@ftp_active_mode
          ftp.login(@user, @pass)
          @directories.each do |cwd|
            ftp.voidcmd("CWD #{cwd}")
          end
        end

        def disconnect
          ftp.close
        end

        # Fetches using Net::FTP, returns a Tempfile with the content
        def get
          tempfile = Chef::FileContentManagement::Tempfile.new(@new_resource).tempfile
          if @typecode
            ftp.voidcmd("TYPE #{@typecode.upcase}")
          end
          ftp.getbinaryfile(@filename, tempfile.path)
          tempfile
        end

        #adapted from buildr/lib/buildr/core/transports.rb via chef/rest/rest_client.rb
        def proxy_uri(uri)
          proxy = Chef::Config["ftp_proxy"]
          proxy = URI.parse(proxy) if String === proxy
          if Chef::Config["ftp_proxy_user"]
            proxy.user = Chef::Config["ftp_proxy_user"]
          end
          if Chef::Config["ftp_proxy_pass"]
            proxy.password = Chef::Config["ftp_proxy_pass"]
          end
          excludes = Chef::Config[:no_proxy].to_s.split(/\s*,\s*/).compact
          excludes = excludes.map { |exclude| exclude =~ /:\d+$/ ? exclude : "#{exclude}:*" }
          return proxy unless excludes.any? { |exclude| File.fnmatch(exclude, "#{host}:#{port}") }
        end

        def parse_path(path)
          path = path.sub(%r{\A/}, '%2F') # re-encode the beginning slash because uri library decodes it.
          directories = path.split(%r{/}, -1)
          directories.each {|d|
            d.gsub!(/%([0-9A-Fa-f][0-9A-Fa-f])/) { [$1].pack("H2") }
          }
          unless filename = directories.pop
            raise ArgumentError, "no filename: #{path.inspect}"
          end
          if filename.length == 0 || filename.end_with?( "/" )
            raise ArgumentError, "no filename: #{path.inspect}"
          end
          return directories, filename
        end

      end
    end
  end
end
