#
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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

require "tmpdir"
require "chef/util/path_helper"
require "spec_helper"

describe Chef::Util::PathHelper, "escape_glob" do
  PathHelper = Chef::Util::PathHelper

  it "escapes the glob metacharacters so globbing succeeds" do
    # make a dir
    Dir.mktmpdir("\\silly[dir]") do |dir|
      # add some files
      files = ["some.rb", "file.txt", "names.csv"]
      files.each do |file|
        File.new(File.join(dir, file), "w").close
      end

      pattern = File.join(PathHelper.escape_glob_dir(dir), "*")
      expect(Dir.glob(pattern).map { |x| File.basename(x) }).to match_array(files)
    end
  end
end
