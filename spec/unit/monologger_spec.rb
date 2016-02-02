#
# Copyright:: Copyright 2014-2016, Chef Software Inc.
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

require "chef/monologger"
require "tempfile"
require "spec_helper"

describe MonoLogger do
  it "should disable buffering when passed an IO stream" do
    STDOUT.sync = false
    MonoLogger.new(STDOUT)
    expect(STDOUT.sync).to eq(true)
  end

  describe "when given an object that responds to write and close e.g. IO" do
    it "should use the object directly" do
      stream = StringIO.new
      MonoLogger.new(stream).fatal("Houston, we've had a problem.")
      expect(stream.string).to match(/Houston, we've had a problem./)
    end
  end

  describe "when given an object that is stringable (to_str)" do
    it "should open a File object with the given path" do
      temp_file = Tempfile.new("rspec-monologger-log")
      temp_file.close
      MonoLogger.new(temp_file.path).fatal("Do, or do not. There is no try.")
      expect(File.read(temp_file.path)).to match(/Do, or do not. There is no try./)
    end
  end
end
