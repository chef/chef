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

require 'chef/mixin/shell_out'

class Chef
  class Util
    class Diff
      include Chef::Mixin::ShellOut

      def for_output
        # formatted output to a terminal uses arrays of strings and returns error strings
        @diff.nil? ? [ @error ] : @diff
      end

      def for_reporting
        # caller needs to ensure that new files aren't posted to resource reporting
        return nil if @diff.nil?
        @diff.join("\\n")
      end

      def diff(old_file, new_file)
        # indicates calling code bug: caller is reponsible for making certain both
        # files exist
        raise "old file #{old_file} does not exist" unless File.exists?(old_file)
        raise "new file #{new_file} does not exist" unless File.exists?(new_file)
        @error = catch (:nodiff) do
          do_diff(old_file, new_file)
        end
      end

      private

      def do_diff(old_file, new_file)
        if Chef::Config[:diff_disabled]
          throw :nodiff, "(diff output suppressed by config)"
        end

        diff_filesize_threshold = Chef::Config[:diff_filesize_threshold]
        diff_output_threshold = Chef::Config[:diff_output_threshold]

        if ::File.size(old_file) > diff_filesize_threshold || ::File.size(new_file) > diff_filesize_threshold
          throw :nodiff, "(file sizes exceed #{diff_filesize_threshold} bytes, diff output suppressed)"
        end

        # MacOSX(BSD?) diff will *sometimes* happily spit out nasty binary diffs
        throw :nodiff, "(current file is binary, diff output suppressed)" if is_binary?(old_file)
        throw :nodiff, "(new content is binary, diff output suppressed)" if is_binary?(new_file)

        begin
          # -u: Unified diff format
          result = shell_out("diff -u #{old_file} #{new_file}")
        rescue Exception => e
          # Should *not* receive this, but in some circumstances it seems that
          # an exception can be thrown even using shell_out instead of shell_out!
          throw :nodiff, "Could not determine diff. Error: #{e.message}"
        end

        # diff will set a non-zero return code even when there's
        # valid stdout results, if it encounters something unexpected
        # So as long as we have output, we'll show it.
        if not result.stdout.empty?
          if result.stdout.length > diff_output_threshold
            throw :nodiff, "(long diff of over #{diff_output_threshold} characters, diff output suppressed)"
          else
            @diff = result.stdout.split("\n")
            @diff.delete("\\ No newline at end of file")
            # XXX: successful return of the diff is here, we return nil as no error...  ugh...
            return nil
          end
        elsif not result.stderr.empty?
          throw :nodiff, "Could not determine diff. Error: #{result.stderr}"
        else
          throw :nodiff, "(no diff)"
        end
      end

      def is_binary?(path)
        ::File.open(path) do |file|
          buff = file.read(Chef::Config[:diff_filesize_threshold])
          buff = "" if buff.nil?
          return buff !~ /^[\r[:print:]]*$/
        end
      end

    end
  end
end

