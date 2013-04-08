#
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require "tempfile"

class Chef
  class Provider
    class File
      class Tempfile

        attr_reader :new_resource

        def initialize(new_resource)
          @new_resource = new_resource
        end

        def tempfile
          @tempfile ||= ::Tempfile.open(tempfile_basename, tempfile_dirname, tempfile_flags)
        end

        private

        #
        # These are important for windows to get permissions right, and may
        # be useful for SELinux and other ACL approaches.  Please use them
        # as the arguments to Tempfile.new() consistently.
        #
        def tempfile_basename
          basename = ::File.basename(@new_resource.name)
          basename.insert 0, "." unless Chef::Platform.windows?  # dotfile if we're not on windows
          basename
        end

        def tempfile_dirname
          Chef::Config[:file_deployment_uses_destdir] ? ::File.dirname(@new_resource.path) : Dir::tmpdir
        end

        def tempfile_flags
          if new_resource.binmode
            { :binmode => true }
          else
            {}
          end
        end
      end
    end
  end
end
