#
# Author:: Jesse Campbell (<hikeit@gmail.com>)
# Copyright:: Copyright 2013-2016, Jesse Campbell
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

require "uri"
require "tempfile"
require "net/ftp"
require "chef/provider/remote_file"
require "chef/file_content_management/tempfile"

class Chef
  class Provider
    class RemoteFile
      class FTP

        attr_reader :uri
        attr_reader :new_resource
        attr_reader :current_resource

        def initialize(uri, new_resource, current_resource)
          @uri = uri
          @new_resource = new_resource
          @current_resource = current_resource
          validate_typecode!
          validate_path!
        end

        def hostname
          @uri.host
        end

        def port
          @uri.port
        end

        def use_passive_mode?
          ! new_resource.ftp_active_mode
        end

        def typecode
          uri.typecode
        end

        def user
          if uri.userinfo
            URI.unescape(uri.user)
          else
            "anonymous"
          end
        end

        def pass
          if uri.userinfo
            URI.unescape(uri.password)
          else
            nil
          end
        end

        def directories
          parse_path if @directories.nil?
          @directories
        end

        def filename
          parse_path if @filename.nil?
          @filename
        end

        def fetch
          with_connection do
            get
          end
        end

        def ftp
          @ftp ||= Net::FTP.new
        end

        private

        def with_proxy_env
          saved_socks_env = ENV["SOCKS_SERVER"]
          ENV["SOCKS_SERVER"] = proxy_uri(@uri).to_s
          yield
        ensure
          ENV["SOCKS_SERVER"] = saved_socks_env
        end

        def with_connection
          with_proxy_env do
            connect
            yield
          end
        ensure
          disconnect
        end

        def validate_typecode!
          # Only support ascii and binary types
          if typecode && /\A[ai]\z/ !~ typecode
            raise ArgumentError, "invalid typecode: #{typecode.inspect}"
          end
        end

        def validate_path!
          parse_path
        end

        def connect
          # The access sequence is defined by RFC 1738
          ftp.connect(hostname, port)
          ftp.passive = use_passive_mode?
          ftp.login(user, pass)
          directories.each do |cwd|
            ftp.voidcmd("CWD #{cwd}")
          end
        end

        def disconnect
          ftp.close
        end

        # Fetches using Net::FTP, returns a Tempfile with the content
        def get
          tempfile = Chef::FileContentManagement::Tempfile.new(@new_resource).tempfile
          if typecode
            ftp.voidcmd("TYPE #{typecode.upcase}")
          end
          ftp.getbinaryfile(filename, tempfile.path)
          tempfile.close if tempfile
          tempfile
        end

        def proxy_uri(uri)
          Chef::Config.proxy_uri("ftp", hostname, port)
        end

        def parse_path
          path = uri.path.sub(%r{\A/}, "%2F") # re-encode the beginning slash because uri library decodes it.
          directories = path.split(%r{/}, -1)
          directories.each do |d|
            d.gsub!(/%([0-9A-Fa-f][0-9A-Fa-f])/) { [$1].pack("H2") }
          end
          unless filename = directories.pop
            raise ArgumentError, "no filename: #{path.inspect}"
          end
          if filename.length == 0 || filename.end_with?( "/" )
            raise ArgumentError, "no filename: #{path.inspect}"
          end

          @directories, @filename = directories, filename
        end

      end
    end
  end
end
