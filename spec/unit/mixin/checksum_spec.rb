#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2009-2016, Chef Software Inc.
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
require "chef/mixin/checksum"
require "stringio"

class Chef::CMCCheck
  include Chef::Mixin::Checksum
end

describe Chef::Mixin::Checksum do
  before(:each) do
    @checksum_user = Chef::CMCCheck.new
    @cache = Chef::Digester.instance
    @file = CHEF_SPEC_DATA + "/checksum/random.txt"
    @stat = double("File::Stat", { :mtime => Time.at(0) })
    allow(File).to receive(:stat).and_return(@stat)
  end

  it "gets the checksum of a file" do
    expect(@checksum_user.checksum(@file)).to eq("09ee9c8cc70501763563bcf9c218d71b2fbf4186bf8e1e0da07f0f42c80a3394")
  end

  describe "short_cksum" do
    context "nil provided for checksum" do
      it "returns none" do
        expect(@checksum_user.short_cksum(nil)).to eq("none")
      end
    end

    context "non-nil provided for checksum" do
      it "returns the short checksum" do
        expect(@checksum_user.short_cksum("u7ghbxikk3i9blsimmy2y2ionmxx")).to eq("u7ghbx")
      end
    end
  end

end
