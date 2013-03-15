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

class Chef
  class Provider
    class File
      class Content

        def initialize(new_resource, current_resource, run_context)
          @new_resource = new_resource
          @current_resource = current_resource
          @run_context = run_context
        end

        def run_context
          @run_context
        end

        def new_resource
          @new_resource
        end

        def current_resource
          @current_resource
        end

        def tempfile
          @tempfile ||= file_for_provider
        end

        private

        #
        # Return something that looks like a File or Tempfile and
        # you must assume the provider will unlink this file.  Copy
        # the contents to a Tempfile if you need to.
        #
        def file_for_provider
          raise "class must implement file_for_provider!"
        end

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

      end
    end
  end
end
