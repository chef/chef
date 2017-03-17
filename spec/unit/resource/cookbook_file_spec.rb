#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2010-2017, Chef Software Inc.
#p License:: Apache License, Version 2.0
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

describe Chef::Resource::CookbookFile do
  before do
    @cookbook_file = Chef::Resource::CookbookFile.new("sourcecode_tarball.tgz")
  end

  it "uses the name parameter for the source parameter" do
    expect(@cookbook_file.name).to eq("sourcecode_tarball.tgz")
  end

  it "has a source parameter" do
    @cookbook_file.name("config_file.conf")
    expect(@cookbook_file.name).to eq("config_file.conf")
  end

  it "defaults to a nil cookbook parameter (current cookbook will be used)" do
    expect(@cookbook_file.cookbook).to be_nil
  end

  it "has a cookbook parameter" do
    @cookbook_file.cookbook("munin")
    expect(@cookbook_file.cookbook).to eq("munin")
  end

  it "sets the provider to Chef::Provider::CookbookFile" do
    expect(@cookbook_file.provider).to eq(Chef::Provider::CookbookFile)
  end

  describe "when it has a backup number, group, mode, owner, source, checksum, and cookbook on nix or path, rights, deny_rights, checksum on windows" do
    before do
      if Chef::Platform.windows?
        @cookbook_file.path("C:/temp/origin/file.txt")
        @cookbook_file.rights(:read, "Everyone")
        @cookbook_file.deny_rights(:full_control, "Clumsy_Sam")
      else
        @cookbook_file.path("/tmp/origin/file.txt")
        @cookbook_file.group("wheel")
        @cookbook_file.mode("0664")
        @cookbook_file.owner("root")
        @cookbook_file.source("/tmp/foo.txt")
        @cookbook_file.cookbook("/tmp/cookbooks/cooked.rb")
      end
      @cookbook_file.checksum("1" * 64)
    end

    it "describes the state" do
      state = @cookbook_file.state_for_resource_reporter
      if Chef::Platform.windows?
        puts state
        expect(state[:rights]).to eq([{ :permissions => :read, :principals => "Everyone" }])
        expect(state[:deny_rights]).to eq([{ :permissions => :full_control, :principals => "Clumsy_Sam" }])
      else
        expect(state[:group]).to eq("wheel")
        expect(state[:mode]).to eq("0664")
        expect(state[:owner]).to eq("root")
      end
      expect(state[:checksum]).to eq("1" * 64)
    end

    it "returns the path as its identity" do
      if Chef::Platform.windows?
        expect(@cookbook_file.identity).to eq("C:/temp/origin/file.txt")
      else
        expect(@cookbook_file.identity).to eq("/tmp/origin/file.txt")
      end
    end
  end
end
