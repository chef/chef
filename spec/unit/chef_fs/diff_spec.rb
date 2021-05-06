#
# Author:: John Keiser (<jkeiser@chef.io>)
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

require "spec_helper"
require "chef/chef_fs/file_pattern"
require "chef/chef_fs/command_line"

describe "diff", uses_diff: true, ruby: ">= 3.0" do
  include FileSystemSupport

  # Removes the date stamp from the diff and replaces it with ' DATE'
  # example match: "/dev/null\t2012-10-16 16:15:54.000000000 +0000"
  # windows match: "--- /dev/null\tTue Oct 16 18:04:34 2012"
  def remove_os_differences(diff)
    diff = diff.gsub(/([+-]{3}.*)\t.*/, '\1 DATE')
    diff.gsub(/^@@ -\d(,\d)? \+\d(,\d)? @@/, "CONTEXT_LINE_NUMBERS")
  end

  context "with two filesystems with all types of difference" do
    let(:a) do
      memory_fs("a", {
        both_dirs: {
          sub_both_dirs: { subsub: nil },
          sub_both_files: nil,
          sub_both_files_different: "a\n",
          sub_both_dirs_empty: {},
          sub_dirs_empty_in_a_filled_in_b: {},
          sub_dirs_empty_in_b_filled_in_a: { subsub: nil },
          sub_a_only_dir: { subsub: nil },
          sub_a_only_file: nil,
          sub_dir_in_a_file_in_b: {},
          sub_file_in_a_dir_in_b: nil,
        },
        both_files: nil,
        both_files_different: "a\n",
        both_dirs_empty: {},
        dirs_empty_in_a_filled_in_b: {},
        dirs_empty_in_b_filled_in_a: { subsub: nil },
        dirs_in_a_cannot_be_in_b: {},
        file_in_a_cannot_be_in_b: nil,
        a_only_dir: { subsub: nil },
        a_only_file: nil,
        dir_in_a_file_in_b: {},
        file_in_a_dir_in_b: nil,
      }, /cannot_be_in_a/)
    end
    let(:b) do
      memory_fs("b", {
        both_dirs: {
          sub_both_dirs: { subsub: nil },
          sub_both_files: nil,
          sub_both_files_different: "b\n",
          sub_both_dirs_empty: {},
          sub_dirs_empty_in_a_filled_in_b: { subsub: nil },
          sub_dirs_empty_in_b_filled_in_a: {},
          sub_b_only_dir: { subsub: nil },
          sub_b_only_file: nil,
          sub_dir_in_a_file_in_b: nil,
          sub_file_in_a_dir_in_b: {},
        },
        both_files: nil,
        both_files_different: "b\n",
        both_dirs_empty: {},
        dirs_empty_in_a_filled_in_b: { subsub: nil },
        dirs_empty_in_b_filled_in_a: {},
        dirs_in_b_cannot_be_in_a: {},
        file_in_b_cannot_be_in_a: nil,
        b_only_dir: { subsub: nil },
        b_only_file: nil,
        dir_in_a_file_in_b: nil,
        file_in_a_dir_in_b: {},
      }, /cannot_be_in_b/)
    end
    it "Chef::ChefFS::CommandLine.diff_print(/)" do
      results = []
      Chef::ChefFS::CommandLine.diff_print(pattern("/"), a, b, nil, nil) do |diff|
        results << remove_os_differences(diff)
      end
      expect(results).to match_array([
        'diff --knife a/both_dirs/sub_both_files_different b/both_dirs/sub_both_files_different
--- a/both_dirs/sub_both_files_different DATE
+++ b/both_dirs/sub_both_files_different DATE
CONTEXT_LINE_NUMBERS
-a
+b
', 'diff --knife a/both_dirs/sub_dirs_empty_in_a_filled_in_b/subsub b/both_dirs/sub_dirs_empty_in_a_filled_in_b/subsub
new file
--- /dev/null DATE
+++ b/both_dirs/sub_dirs_empty_in_a_filled_in_b/subsub DATE
CONTEXT_LINE_NUMBERS
+subsub
', 'diff --knife a/both_dirs/sub_dirs_empty_in_b_filled_in_a/subsub b/both_dirs/sub_dirs_empty_in_b_filled_in_a/subsub
deleted file
--- a/both_dirs/sub_dirs_empty_in_b_filled_in_a/subsub DATE
+++ /dev/null DATE
CONTEXT_LINE_NUMBERS
-subsub
', "Only in a/both_dirs: sub_a_only_dir
", 'diff --knife a/both_dirs/sub_a_only_file b/both_dirs/sub_a_only_file
deleted file
--- a/both_dirs/sub_a_only_file DATE
+++ /dev/null DATE
CONTEXT_LINE_NUMBERS
-sub_a_only_file
', "File a/both_dirs/sub_dir_in_a_file_in_b is a directory while file b/both_dirs/sub_dir_in_a_file_in_b is a regular file
", "File a/both_dirs/sub_file_in_a_dir_in_b is a regular file while file b/both_dirs/sub_file_in_a_dir_in_b is a directory
", "Only in b/both_dirs: sub_b_only_dir
", 'diff --knife a/both_dirs/sub_b_only_file b/both_dirs/sub_b_only_file
new file
--- /dev/null DATE
+++ b/both_dirs/sub_b_only_file DATE
CONTEXT_LINE_NUMBERS
+sub_b_only_file
', 'diff --knife a/both_files_different b/both_files_different
--- a/both_files_different DATE
+++ b/both_files_different DATE
CONTEXT_LINE_NUMBERS
-a
+b
', 'diff --knife a/dirs_empty_in_a_filled_in_b/subsub b/dirs_empty_in_a_filled_in_b/subsub
new file
--- /dev/null DATE
+++ b/dirs_empty_in_a_filled_in_b/subsub DATE
CONTEXT_LINE_NUMBERS
+subsub
', 'diff --knife a/dirs_empty_in_b_filled_in_a/subsub b/dirs_empty_in_b_filled_in_a/subsub
deleted file
--- a/dirs_empty_in_b_filled_in_a/subsub DATE
+++ /dev/null DATE
CONTEXT_LINE_NUMBERS
-subsub
', "Only in a: a_only_dir
", 'diff --knife a/a_only_file b/a_only_file
deleted file
--- a/a_only_file DATE
+++ /dev/null DATE
CONTEXT_LINE_NUMBERS
-a_only_file
', "File a/dir_in_a_file_in_b is a directory while file b/dir_in_a_file_in_b is a regular file
", "File a/file_in_a_dir_in_b is a regular file while file b/file_in_a_dir_in_b is a directory
", "Only in b: b_only_dir
", 'diff --knife a/b_only_file b/b_only_file
new file
--- /dev/null DATE
+++ b/b_only_file DATE
CONTEXT_LINE_NUMBERS
+b_only_file
' ])
    end
    it "Chef::ChefFS::CommandLine.diff_print(/both_dirs)" do
      results = []
      Chef::ChefFS::CommandLine.diff_print(pattern("/both_dirs"), a, b, nil, nil) do |diff|
        results << remove_os_differences(diff)
      end
      expect(results).to match_array([
        'diff --knife a/both_dirs/sub_both_files_different b/both_dirs/sub_both_files_different
--- a/both_dirs/sub_both_files_different DATE
+++ b/both_dirs/sub_both_files_different DATE
CONTEXT_LINE_NUMBERS
-a
+b
', 'diff --knife a/both_dirs/sub_dirs_empty_in_a_filled_in_b/subsub b/both_dirs/sub_dirs_empty_in_a_filled_in_b/subsub
new file
--- /dev/null DATE
+++ b/both_dirs/sub_dirs_empty_in_a_filled_in_b/subsub DATE
CONTEXT_LINE_NUMBERS
+subsub
', 'diff --knife a/both_dirs/sub_dirs_empty_in_b_filled_in_a/subsub b/both_dirs/sub_dirs_empty_in_b_filled_in_a/subsub
deleted file
--- a/both_dirs/sub_dirs_empty_in_b_filled_in_a/subsub DATE
+++ /dev/null DATE
CONTEXT_LINE_NUMBERS
-subsub
', "Only in a/both_dirs: sub_a_only_dir
", 'diff --knife a/both_dirs/sub_a_only_file b/both_dirs/sub_a_only_file
deleted file
--- a/both_dirs/sub_a_only_file DATE
+++ /dev/null DATE
CONTEXT_LINE_NUMBERS
-sub_a_only_file
', "File a/both_dirs/sub_dir_in_a_file_in_b is a directory while file b/both_dirs/sub_dir_in_a_file_in_b is a regular file
", "File a/both_dirs/sub_file_in_a_dir_in_b is a regular file while file b/both_dirs/sub_file_in_a_dir_in_b is a directory
", "Only in b/both_dirs: sub_b_only_dir
", 'diff --knife a/both_dirs/sub_b_only_file b/both_dirs/sub_b_only_file
new file
--- /dev/null DATE
+++ b/both_dirs/sub_b_only_file DATE
CONTEXT_LINE_NUMBERS
+sub_b_only_file
' ])
    end
    it "Chef::ChefFS::CommandLine.diff_print(/) with depth 1" do
      results = []
      Chef::ChefFS::CommandLine.diff_print(pattern("/"), a, b, 1, nil) do |diff|
        results << remove_os_differences(diff)
      end
      expect(results).to match_array([
"Common subdirectories: b/both_dirs
", 'diff --knife a/both_files_different b/both_files_different
--- a/both_files_different DATE
+++ b/both_files_different DATE
CONTEXT_LINE_NUMBERS
-a
+b
', "Common subdirectories: b/both_dirs_empty
", "Common subdirectories: b/dirs_empty_in_b_filled_in_a
", "Common subdirectories: b/dirs_empty_in_a_filled_in_b
", "Only in a: a_only_dir
", 'diff --knife a/a_only_file b/a_only_file
deleted file
--- a/a_only_file DATE
+++ /dev/null DATE
CONTEXT_LINE_NUMBERS
-a_only_file
', "File a/dir_in_a_file_in_b is a directory while file b/dir_in_a_file_in_b is a regular file
", "File a/file_in_a_dir_in_b is a regular file while file b/file_in_a_dir_in_b is a directory
", "Only in b: b_only_dir
", 'diff --knife a/b_only_file b/b_only_file
new file
--- /dev/null DATE
+++ b/b_only_file DATE
CONTEXT_LINE_NUMBERS
+b_only_file
' ])
    end
    it "Chef::ChefFS::CommandLine.diff_print(/*_*) with depth 0" do
      results = []
      Chef::ChefFS::CommandLine.diff_print(pattern("/*_*"), a, b, 0, nil) do |diff|
        results << remove_os_differences(diff)
      end
      expect(results).to match_array([
"Common subdirectories: b/both_dirs
", 'diff --knife a/both_files_different b/both_files_different
--- a/both_files_different DATE
+++ b/both_files_different DATE
CONTEXT_LINE_NUMBERS
-a
+b
', "Common subdirectories: b/both_dirs_empty
", "Common subdirectories: b/dirs_empty_in_b_filled_in_a
", "Common subdirectories: b/dirs_empty_in_a_filled_in_b
", "Only in a: a_only_dir
", 'diff --knife a/a_only_file b/a_only_file
deleted file
--- a/a_only_file DATE
+++ /dev/null DATE
CONTEXT_LINE_NUMBERS
-a_only_file
', "File a/dir_in_a_file_in_b is a directory while file b/dir_in_a_file_in_b is a regular file
", "File a/file_in_a_dir_in_b is a regular file while file b/file_in_a_dir_in_b is a directory
", "Only in b: b_only_dir
", 'diff --knife a/b_only_file b/b_only_file
new file
--- /dev/null DATE
+++ b/b_only_file DATE
CONTEXT_LINE_NUMBERS
+b_only_file
' ])
    end
    it "Chef::ChefFS::CommandLine.diff_print(/) in name-only mode" do
      results = []
      Chef::ChefFS::CommandLine.diff_print(pattern("/"), a, b, nil, :name_only) do |diff|
        results << remove_os_differences(diff)
      end
      expect(results).to match_array([
          "b/both_dirs/sub_both_files_different\n",
          "b/both_dirs/sub_dirs_empty_in_b_filled_in_a/subsub\n",
          "b/both_dirs/sub_dirs_empty_in_a_filled_in_b/subsub\n",
          "b/both_dirs/sub_a_only_dir\n",
          "b/both_dirs/sub_a_only_file\n",
          "b/both_dirs/sub_b_only_dir\n",
          "b/both_dirs/sub_b_only_file\n",
          "b/both_dirs/sub_dir_in_a_file_in_b\n",
          "b/both_dirs/sub_file_in_a_dir_in_b\n",
          "b/both_files_different\n",
          "b/dirs_empty_in_b_filled_in_a/subsub\n",
          "b/dirs_empty_in_a_filled_in_b/subsub\n",
          "b/a_only_dir\n",
          "b/a_only_file\n",
          "b/b_only_dir\n",
          "b/b_only_file\n",
          "b/dir_in_a_file_in_b\n",
          "b/file_in_a_dir_in_b\n",
      ])
    end
    it "Chef::ChefFS::CommandLine.diff_print(/) in name-status mode" do
      results = []
      Chef::ChefFS::CommandLine.diff_print(pattern("/"), a, b, nil, :name_status) do |diff|
        results << remove_os_differences(diff)
      end
      expect(results).to match_array([
          "M\tb/both_dirs/sub_both_files_different\n",
          "D\tb/both_dirs/sub_dirs_empty_in_b_filled_in_a/subsub\n",
          "A\tb/both_dirs/sub_dirs_empty_in_a_filled_in_b/subsub\n",
          "D\tb/both_dirs/sub_a_only_dir\n",
          "D\tb/both_dirs/sub_a_only_file\n",
          "A\tb/both_dirs/sub_b_only_dir\n",
          "A\tb/both_dirs/sub_b_only_file\n",
          "T\tb/both_dirs/sub_dir_in_a_file_in_b\n",
          "T\tb/both_dirs/sub_file_in_a_dir_in_b\n",
          "M\tb/both_files_different\n",
          "D\tb/dirs_empty_in_b_filled_in_a/subsub\n",
          "A\tb/dirs_empty_in_a_filled_in_b/subsub\n",
          "D\tb/a_only_dir\n",
          "D\tb/a_only_file\n",
          "A\tb/b_only_dir\n",
          "A\tb/b_only_file\n",
          "T\tb/dir_in_a_file_in_b\n",
          "T\tb/file_in_a_dir_in_b\n",
      ])
    end
  end
end
