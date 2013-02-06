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
        # Taken from open-uri
        def self.fetch(uri, ftp_active_mode)
          path = uri.path
          path = path.sub(%r{\A/}, '%2F') # re-encode the beginning slash because uri library decodes it.
          directories = path.split(%r{/}, -1)
          directories.each {|d|
            d.gsub!(/%([0-9A-Fa-f][0-9A-Fa-f])/) { [$1].pack("H2") }
          }
          unless filename = directories.pop
            raise ArgumentError, "no filename: #{uri.inspect}"
          end
          if filename.length == 0 || filename.end_with?( "/" )
            raise ArgumentError, "no filename: #{uri.inspect}"
          end
          typecode = uri.typecode
          # Only support ascii and binary types
          if typecode && /\A[ai]\z/ !~ typecode
            raise ArgumentError, "invalid typecode: #{typecode.inspect}"
          end

          tempfile = Tempfile.new(filename)

          # The access sequence is defined by RFC 1738
          ftp = Net::FTP.new
          ftp.connect(uri.hostname, uri.port)
          ftp.passive = !ftp_active_mode
          user = 'anonymous'
          passwd = nil
          if uri.userinfo
            user = URI.unescape(uri.user)
            passwd = URI.unescape(uri.password)
          end
          ftp.login(user, passwd)
          directories.each {|cwd|
            ftp.voidcmd("CWD #{cwd}")
          }
          if typecode
            ftp.voidcmd("TYPE #{typecode.upcase}")
          end
          ftp.getbinaryfile(filename, tempfile.path)
          ftp.close

          tempfile
        end
      end
    end
  end
end
