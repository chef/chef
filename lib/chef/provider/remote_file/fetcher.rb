#
# Author:: Jesse Campbell (<hikeit@gmail.com>)
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

class Chef
  class Provider
    class RemoteFile
      class Fetcher

        def self.for_resource(uri, new_resource, current_resource)
          if network_share?(uri)
            unless ChefUtils.windows?
              raise Exceptions::UnsupportedPlatform, "Fetching the file on a network share is supported only on the Windows platform. Please change your source: #{uri}"
            end

            Chef::Provider::RemoteFile::NetworkFile.new(uri, new_resource, current_resource)
          else
            case uri.scheme
            when "http", "https"
              Chef::Provider::RemoteFile::HTTP.new(uri, new_resource, current_resource)
            when "ftp"
              Chef::Provider::RemoteFile::FTP.new(uri, new_resource, current_resource)
            when "sftp"
              Chef::Provider::RemoteFile::SFTP.new(uri, new_resource, current_resource)
            when "file"
              Chef::Provider::RemoteFile::LocalFile.new(uri, new_resource, current_resource)
            else
              raise ArgumentError, "Invalid uri, Only http(s), ftp, and file are currently supported"
            end
          end
        end

        # Windows network share: \\computername\share\file
        def self.network_share?(source)
          case source
          when String
            !!(/\A\\\\[A-Za-z0-9+\-\.]+/ =~ source)
          else
            false
          end
        end

      end
    end
  end
end
