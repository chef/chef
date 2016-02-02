#
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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

RSpec.shared_context "Win32" do
  before(:all) do
    @original_win32 = if defined?(Win32)
                        win32 = Object.send(:const_get, "Win32")
                        Object.send(:remove_const, "Win32")
                        win32
                      else
                        nil
                      end
    Win32 = Module.new
  end

  after(:all) do
    Object.send(:remove_const, "Win32") if defined?(Win32)
    Object.send(:const_set, "Win32", @original_win32) if @original_win32
  end
end
