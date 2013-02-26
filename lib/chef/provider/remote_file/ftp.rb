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

class Chef
  class Provider
    class RemoteFile
      class FTP

        # Fetches the file at uri using Net::FTP, returning a Tempfile
        def self.fetch(uri, ftp_active_mode)
          ftp = self.new(uri, ftp_active_mode)
          ftp.connect
          tempfile = ftp.fetch
          ftp.disconnect
          tempfile
        end

        def self.fetch_if_modified(uri, ftp_active_mode, last_modified)
          ftp = self.new(uri, ftp_active_mode)
          ftp.connect
          mtime = ftp.mtime
          if mtime && last_modified && mtime.to_i <= last_modified.to_i
            tempfile = nil
          else
            tempfile = ftp.fetch
          end
          ftp.disconnect
          return tempfile, mtime
        end

        # Parse the uri into instance variables
        def initialize(uri, ftp_active_mode)
          @directories, @filename = parse_path(uri.path)
          @typecode = uri.typecode
          # Only support ascii and binary types
          if @typecode && /\A[ai]\z/ !~ @typecode
            raise ArgumentError, "invalid typecode: #{@typecode.inspect}"
          end
          @ftp_active_mode = ftp_active_mode
          @hostname = uri.hostname
          @port = uri.port
          @ftp = Net::FTP.new
          if uri.userinfo
            @user = URI.unescape(uri.user)
            @pass = URI.unescape(uri.password)
          else
            @user = 'anonymous'
            @pass = nil
          end
        end

        def connect
          # The access sequence is defined by RFC 1738
          @ftp.connect(@hostname, @port)
          @ftp.passive = !@ftp_active_mode
          @ftp.login(@user, @pass)
          @directories.each do |cwd|
            @ftp.voidcmd("CWD #{cwd}")
          end
        end

        def disconnect
          @ftp.close
        end

        def mtime
          @ftp.mtime(@filename)
        end

        # Fetches using Net::FTP, returns a Tempfile with the content
        def fetch
          tempfile = Tempfile.new(@filename)
          if @typecode
            @ftp.voidcmd("TYPE #{@typecode.upcase}")
          end
          @ftp.getbinaryfile(@filename, tempfile.path)
          tempfile
        end

        private

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
