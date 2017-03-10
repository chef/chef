#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

class XMLEscapingTestHarness
  include Chef::Mixin::XMLEscape
end

describe Chef::Mixin::XMLEscape do
  before do
    @escaper = XMLEscapingTestHarness.new
  end

  it "escapes ampersands to '&amp;'" do
    expect(@escaper.xml_escape("&")).to eq("&amp;")
  end

  it "escapes angle brackets to &lt; or &gt;" do
    expect(@escaper.xml_escape("<")).to eq("&lt;")
    expect(@escaper.xml_escape(">")).to eq("&gt;")
  end

  it "does not modify ASCII strings" do
    expect(@escaper.xml_escape("foobarbaz!@\#$%^*()")).to eq("foobarbaz!@\#$%^*()")
  end

  it "converts invalid bytes to asterisks" do
    expect(@escaper.xml_escape("\x00")).to eq("*")
  end

  it "converts UTF-8 correctly" do
    expect(@escaper.xml_escape("\xC2\xA9")).to eq("&#169;")
  end

  it "converts win 1252 characters correctly" do
    expect(@escaper.xml_escape("#{0x80.chr}")).to eq("&#8364;")
  end
end
