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

      # @todo: to_a, to_s, to_json, inspect defs, accessors for @diff and @error
      # @todo: move coercion to UTF-8 into to_json
      # @todo: replace shellout to diff -u with diff-lcs gem

      def for_output
        # formatted output to a terminal uses arrays of strings and returns error strings
        @diff.nil? ? [ @error ] : @diff
      end

      def for_reporting
        # caller needs to ensure that new files aren't posted to resource reporting
        return nil if @diff.nil?
        @diff.join("\\n")
      end

      def use_tempfile_if_missing(file)
        tempfile = nil
        unless File.exists?(file)
          Chef::Log.debug("file #{file} does not exist to diff against, using empty tempfile")
          tempfile = Tempfile.new("chef-diff")
          file = tempfile.path
        end
        yield file
        unless tempfile.nil?
          tempfile.close
          tempfile.unlink
        end
      end

      def diff(old_file, new_file)
        use_tempfile_if_missing(old_file) do |old_file|
          use_tempfile_if_missing(new_file) do |new_file|
            @error = do_diff(old_file, new_file)
          end
        end
      end

      private

      def do_diff(old_file, new_file)
        if Chef::Config[:diff_disabled]
          return "(diff output suppressed by config)"
        end

        diff_filesize_threshold = Chef::Config[:diff_filesize_threshold]
        diff_output_threshold = Chef::Config[:diff_output_threshold]

        if ::File.size(old_file) > diff_filesize_threshold || ::File.size(new_file) > diff_filesize_threshold
          return "(file sizes exceed #{diff_filesize_threshold} bytes, diff output suppressed)"
        end

        # MacOSX(BSD?) diff will *sometimes* happily spit out nasty binary diffs
        return "(current file is binary, diff output suppressed)" if is_binary?(old_file)
        return "(new content is binary, diff output suppressed)" if is_binary?(new_file)

        begin
          # -u: Unified diff format
          # LC_ALL: in ruby 1.9 we want to set nil which is a magic option to mixlib-shellout to
          #         pass through the LC_ALL locale.  in ruby 1.8 we force to 7-bit 'C' locale
          #         (which is the mixlib-shellout default for all rubies all the time).
          Chef::Log.debug("running: diff -u #{old_file} #{new_file}")
          locale = ( Object.const_defined? :Encoding ) ? nil : 'C'
          result = shell_out("diff -u #{old_file} #{new_file}", :env => {'LC_ALL' => locale})

        rescue Exception => e
          # Should *not* receive this, but in some circumstances it seems that
          # an exception can be thrown even using shell_out instead of shell_out!
          return "Could not determine diff. Error: #{e.message}"
        end

        # diff will set a non-zero return code even when there's
        # valid stdout results, if it encounters something unexpected
        # So as long as we have output, we'll show it.
        #
        # Also on some platforms (Solaris) diff outputs a single line
        # when there are no differences found. Look for this line
        # before analyzing diff output.
        if !result.stdout.empty? && result.stdout != "No differences encountered\n"
          if result.stdout.length > diff_output_threshold
            return "(long diff of over #{diff_output_threshold} characters, diff output suppressed)"
          else
            diff_str = result.stdout
            if  Object.const_defined? :Encoding  # ruby >= 1.9
              if ( diff_str.encoding == Encoding::ASCII_8BIT &&
                diff_str.encoding != Encoding.default_external &&
                RUBY_VERSION.to_f < 2.0 )
                # @todo mixlib-shellout under ruby 1.9 hands back an ASCII-8BIT encoded string, which needs to
                # be fixed to the default external encoding -- this should be moved into mixlib-shellout
                diff_str = diff_str.force_encoding(Encoding.default_external)
              end
              diff_str.encode!('UTF-8', :invalid => :replace, :undef => :replace, :replace => '?')
            end
            @diff = diff_str.split("\n")
            @diff.delete("\\ No newline at end of file")
            return "(diff available)"
          end
        elsif !result.stderr.empty?
          return "Could not determine diff. Error: #{result.stderr}"
        else
          return "(no diff)"
        end
      end

      def is_binary?(path)
        File.open(path) do |file|
          # XXX: this slurps into RAM, but we should have already checked our diff has a reasonable size
          buff = file.read
          buff = "" if buff.nil?
          begin
            return buff !~ /\A[\s[:print:]]*\z/m
          rescue ArgumentError => e
            return true if e.message =~ /invalid byte sequence/
            raise
          end
        end
      end

    end
  end
end

