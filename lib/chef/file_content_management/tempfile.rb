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
  class FileContentManagement
    class Tempfile

      attr_reader :new_resource

      def initialize(new_resource)
        @new_resource = new_resource
      end

      def tempfile
        @tempfile ||= tempfile_open
      end

      private

      def tempfile_open
        tf = ::Tempfile.open(tempfile_basename, tempfile_dirname)
        # We always process the tempfile in binmode so that we
        # preserve the line endings of the content.
        tf.binmode
        tf
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
        Chef::Config[:file_staging_uses_destdir] ? ::File.dirname(@new_resource.path) : Dir::tmpdir
      end
    end
  end
end
