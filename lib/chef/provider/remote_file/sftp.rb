#
# Author:: John Kerry (<john@kerryhouse.net>)
# Copyright:: Copyright 2013-2016, John Kerry
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
require "net/sftp"
require "chef/provider/remote_file"
require "chef/file_content_management/tempfile"

class Chef
  class Provider
    class RemoteFile
      class SFTP
        attr_reader :uri
        attr_reader :new_resource
        attr_reader :current_resource

        def initialize(uri, new_resource, current_resource)
          @uri = uri
          @new_resource = new_resource
          @current_resource = current_resource
          validate_path!
          validate_userinfo!
        end

        def hostname
          @uri.host
        end

        def port
          @uri.port
        end

        def user
          URI.unescape(uri.user)
        end

        def fetch
          get
        end

        private

        def sftp
          host = port ? "#{hostname}:#{port}" : hostname
          @sftp ||= Net::SFTP.start(host, user, :password => pass)
        end

        def pass
          URI.unescape(uri.password)
        end

        def validate_path!
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
        end

        def validate_userinfo!
          if uri.userinfo
            unless uri.user
              raise ArgumentError, "no user name provided in the sftp URI"
            end
            unless uri.password
              raise ArgumentError, "no password provided in the sftp URI"
            end
          else
            raise ArgumentError, "no userinfo provided in the sftp URI"
          end
        end

        def get
          tempfile =
            Chef::FileContentManagement::Tempfile.new(@new_resource).tempfile
          sftp.download!(uri.path, tempfile.path)
          tempfile.close if tempfile
          tempfile
        end
      end
    end
  end
end
