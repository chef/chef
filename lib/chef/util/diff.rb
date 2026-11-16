# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
# Some portions of this file are derived from material in the diff-lcs
# project licensed under the terms of the MIT license, provided below.
#
# Copyright:: Copyright 2004-2016, Austin Ziegler
# License:: MIT
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of this Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OF OTHER DEALINGS IN THE
# SOFTWARE.

class Chef
  class Util
    class Diff
      # @todo: to_a, to_s, to_json, inspect defs, accessors for @diff and @error
      # @todo: move coercion to UTF-8 into to_json

      def for_output
        # formatted output to a terminal uses arrays of strings and returns error strings
        @diff.nil? ? [ @error ] : @diff
      end

      def for_reporting
        # caller needs to ensure that new files aren't posted to resource reporting
        return nil if @diff.nil?

        @diff.join("\\n")
      end

      # @param file [String] path to check/stage for diffing
      # @param local [Boolean] whether `file` is always a path on the chef-client
      #   host itself (e.g. an already-rendered content tempfile), as opposed to a
      #   path on the Target Mode target node. Local paths must never be checked
      #   for existence or downloaded via the target transport connection -- under
      #   Target Mode there is no remote equivalent of that path to look up, and
      #   doing so would incorrectly report the file as missing (or, for
      #   coincidentally-colliding path names, attempt to download the wrong file).
      def use_tempfile_if_missing(file, local: false)
        tempfile = nil

        if local
          unless ::File.exist?(file)
            Chef::Log.trace("File #{file} does not exist to diff against, using empty tempfile")
            tempfile = Tempfile.new("chef-diff")
            file = tempfile.path
          end
        elsif ChefConfig::Config.target_mode? && TargetIO::File.exist?(file)
          # The remote (target node) file exists -- stage a local copy of its
          # content so the rest of the diffing logic can work purely with local
          # paths. TargetIO::File.read already handles the sudo-aware staging
          # dance (see TargetIO::Support#read_file), so this works even when the
          # remote file is only readable by root over a `sudo`-enabled Target
          # Mode connection, unlike a raw/unprivileged transport_connection.download.
          tempfile = Tempfile.new("chef-diff")
          tempfile.binmode
          tempfile.write(TargetIO::File.read(file))
          tempfile.close
          file = tempfile.path
        elsif !TargetIO::File.exist?(file)
          Chef::Log.trace("File #{file} does not exist to diff against, using empty tempfile")
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
          # new_file is always a local tempfile with already-rendered content
          # (see Chef::Provider::File#do_contents_changes), never a path that
          # exists on the Target Mode target node -- it must be treated as local.
          use_tempfile_if_missing(new_file, local: true) do |new_file|
            @error = do_diff(old_file, new_file)
          end
        end
      end

      # produces a unified-output-format diff with 3 lines of context
      # ChefFS uses udiff() directly
      def udiff(old_file, new_file)
        require "diff/lcs"
        require "diff/lcs/hunk"

        diff_str = ""
        file_length_difference = 0

        old_data = IO.readlines(old_file).map(&:chomp)
        new_data = IO.readlines(new_file).map(&:chomp)
        diff_data = ::Diff::LCS.diff(old_data, new_data)

        return diff_str if old_data.empty? && new_data.empty?
        return "No differences encountered\n" if diff_data.empty?

        # write diff header (standard unified format)
        ft = File.stat(old_file).mtime.localtime.strftime("%Y-%m-%d %H:%M:%S.%N %z")
        diff_str << "--- #{old_file}\t#{ft}\n"
        ft = File.stat(new_file).mtime.localtime.strftime("%Y-%m-%d %H:%M:%S.%N %z")
        diff_str << "+++ #{new_file}\t#{ft}\n"

        # loop over diff hunks. if a hunk overlaps with the last hunk,
        # join them. otherwise, print out the old one.
        old_hunk = hunk = nil
        diff_data.each do |piece|

          hunk = ::Diff::LCS::Hunk.new(old_data, new_data, piece, 3, file_length_difference)
          file_length_difference = hunk.file_length_difference
          next unless old_hunk
          next if hunk.merge(old_hunk)

          diff_str << old_hunk.diff(:unified) << "\n"
        ensure
          old_hunk = hunk

        end
        diff_str << old_hunk.diff(:unified) << "\n"
        diff_str
      end

      private

      def do_diff(old_file, new_file)
        if Chef::Config[:diff_disabled]
          return "(diff output suppressed by config)"
        end

        diff_filesize_threshold = Chef::Config[:diff_filesize_threshold]
        diff_output_threshold = Chef::Config[:diff_output_threshold]

        # By the time do_diff is called, both old_file and new_file have
        # already been staged to local paths with local content by
        # use_tempfile_if_missing (which also handles the Target Mode case of
        # downloading remote content via the sudo-aware TargetIO::File.read).
        if ::File.size(old_file) > diff_filesize_threshold || ::File.size(new_file) > diff_filesize_threshold
          return "(file sizes exceed #{diff_filesize_threshold} bytes, diff output suppressed)"
        end

        # macOS(BSD?) diff will *sometimes* happily spit out nasty binary diffs
        return "(current file is binary, diff output suppressed)" if is_binary?(old_file)
        return "(new content is binary, diff output suppressed)" if is_binary?(new_file)

        begin
          Chef::Log.trace("Running: diff -u #{old_file} #{new_file}")
          diff_str = udiff(old_file, new_file)

        rescue Exception => e
          # Should *not* receive this, but in some circumstances it seems that
          # an exception can be thrown even using shell_out instead of shell_out!
          return "Could not determine diff. Error: #{e.message}"
        end

        if !diff_str.empty? && diff_str != "No differences encountered\n"
          if diff_str.length > diff_output_threshold
            "(long diff of over #{diff_output_threshold} characters, diff output suppressed)"
          else
            diff_str = encode_diff_for_json(diff_str)
            @diff = diff_str.split("\n")
            "(diff available)"
          end
        else
          "(no diff)"
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
            return true if /invalid byte sequence/.match?(e.message)

            raise
          end
        end
      end

      def encode_diff_for_json(diff_str)
        diff_str.encode!("UTF-8", invalid: :replace, undef: :replace, replace: "?")
      end

    end
  end
end
