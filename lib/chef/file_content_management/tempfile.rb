#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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
        tf = nil
        errors = [ ]

        tempfile_dirnames.each do |tempfile_dirname|
          begin
            # preserving the file extension of the target filename should be considered a public API
            tf = ::Tempfile.open([tempfile_basename, tempfile_extension], tempfile_dirname)
            break
          rescue SystemCallError => e
            message = "Creating temp file under '#{tempfile_dirname}' failed with: '#{e.message}'"
            Chef::Log.debug(message)
            errors << message
          end
        end

        raise Chef::Exceptions::FileContentStagingError, errors if tf.nil?

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
        basename = ::File.basename(@new_resource.path, tempfile_extension)
        # the leading "[.]chef-" here should be considered a public API and should not be changed
        basename.insert 0, "chef-"
        basename.insert 0, "." unless Chef::Platform.windows? # dotfile if we're not on windows
        basename
      end

      # this is similar to File.extname() but greedy about the extension (from the first dot, not the last dot)
      def tempfile_extension
        # complexity here is due to supporting mangling non-UTF8 strings (e.g. latin-1 filenames with characters that are illegal in UTF-8)
        b = File.basename(@new_resource.path)
        i = b.index(".")
        i.nil? ? "" : b[i..-1]
      end

      # Returns the possible directories for the tempfile to be created in.
      def tempfile_dirnames
        # in why-run mode we need to create a Tempfile to compare against, which we will never
        # wind up deploying, but our enclosing directory for the destdir may not exist yet, so
        # instead we can reliably always create a Tempfile to compare against in Dir::tmpdir
        if Chef::Config[:why_run]
          [ Dir.tmpdir ]
        else
          case Chef::Config[:file_staging_uses_destdir]
          when :auto
            # In auto mode we try the destination directory first and fallback to ENV['TMP'] if
            # that doesn't work.
            [ ::File.dirname(@new_resource.path), Dir.tmpdir ]
          when true
            [ ::File.dirname(@new_resource.path) ]
          when false
            [ Dir.tmpdir ]
          else
            raise Chef::Exceptions::ConfigurationError, "Unknown setting '#{Chef::Config[:file_staging_uses_destdir]}' for Chef::Config[:file_staging_uses_destdir]. Possible values are :auto, true or false."
          end
        end
      end

    end
  end
end
