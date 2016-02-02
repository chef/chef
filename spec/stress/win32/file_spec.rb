#
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright 2011-2016, Chef Software Inc.
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
require "chef/win32/file" if windows?

describe "Chef::ReservedNames::Win32::File", :windows_only do
  before(:each) do
    @path = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "data", "old_home_dir", "my-dot-emacs"))
  end

  it "should not leak significant memory", :volatile do
    test = lambda { Chef::ReservedNames::Win32::File.symlink?(@path) }
    expect(test).not_to leak_memory(:warmup => 50000, :iterations => 50000)
  end

  it "should not leak handles", :volatile do
    test = lambda { Chef::ReservedNames::Win32::File.symlink?(@path) }
    expect(test).not_to leak_handles(:warmup => 50, :iterations => 100)
  end

end
