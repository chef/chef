#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2013-2018, Chef Software Inc.
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

require "chef/provider/file/editable_file"

class Chef
  class Provider
    class File < Chef::Provider
      class EditDSL
        extend Forwardable

        # Array<String> lines
        attr_accessor :editor

        def initialize(path)
          editor = EditableFile.new(path)
        end

        #
        # DSL methods
        #

        #
        # CFEngine v2 notes:
        #
        # - AppendIfNoLineMatching
        # - AppendIfNoSuchLine
        # - AppendIfNoSuchLinesFromFile
        # - CommentLinesContaining
        # - CommentLinesMatching
        # - CommentLinesStarting
        # - DeleteLinesAfterThisMatching
        # - DeleteLinesContaining / DeleteLinesNotContaining
        # - DeleteLinesMatching / DeleteLinesNotMatching
        # - DeleteLinesStarting / DeteleLinesNotStarting
        # - DeleteLinesNotContainingFileItems
        # - DeleteLinesNotMatchingFileItems
        # - DeleteLinesNotStartingFileItems
        # - FixEndOfLine
        # - HashCommentLinesContaining
        # - HashCommentLinesMatching
        # - HashCommentLinesStarting
        # - InsertFile (change to InsertFileBeforeMatch/AfterMatch w/N lines)
        # - InsertLine (change to InsertLineBeforeMatch/AfterMatch w/N lines)
        # - PercentCommentLinesContaining
        # - PercentCommentLinesMatching
        # - PercentCommentLinesStarting
        # - PrependIfNoLineMatching
        # - PrependIfNoSuchLine
        # - ReplaceAll/With
        # - ReplaceFirst/With
        # - SetCommentStart/End
        # - SlashCommentLinesContaining
        # - SlashCommentLinesMatching
        # - SlashCommentLinesStarting
        # - UnCommentLinesContaining
        # - UnCommentLinesMatching

        #
        # ADD:
        #
        # - remove_if_empty (true/false) : remove the file if the contents are all deleted (default false)

        def_delegators :@editor, :insert, :replace, :delete, :location, :region, :using

        def self.from_file(path)
          EditableFile.from_file(path)
        end
      end
    end
  end
end
