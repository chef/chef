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
require 'pry'

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

        tempfile_dirnames.each do |tempfile_dirname|
          begin
            tf = ::Tempfile.open(tempfile_basename, tempfile_dirname)
            break
          rescue Exception => e
            Chef::Log.debug("Can not create temp file for staging under '#{tempfile_dirname}'.")
            Chef::Log.debug(e.message)
          end
        end

        raise "Staging tempfile can not be created!" if tf.nil?

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

      # Returns the possible directories for the tempfile to be created in.
      def tempfile_dirnames
        # in why-run mode we need to create a Tempfile to compare against, which we will never
        # wind up deploying, but our enclosing directory for the destdir may not exist yet, so
        # instead we can reliably always create a Tempfile to compare against in Dir::tmpdir
        if Chef::Config[:why_run]
          [ Dir::tmpdir ]
        else
          case Chef::Config[:file_staging_uses_destdir]
          when :auto
            # In auto mode we try the destination directory first and fallback to ENV['TMP'] if
            # that doesn't work.
            [ ::File.dirname(@new_resource.path), Dir::tmpdir ]
          when true
            [ ::File.dirname(@new_resource.path) ]
          when false
            [ Dir::tmpdir ]
          else
            raise "Unknown setting '#{Chef::Config[:file_staging_uses_destdir]}' for Chef::Config[:file_staging_uses_destdir]. Possible values are :auto, true or false."
          end
        end
      end

    end
  end
end
