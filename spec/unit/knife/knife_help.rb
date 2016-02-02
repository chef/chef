#
# Author:: Bryan McLellan <btm@loftninjas.org>
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

describe Chef::Knife::Help do
  before(:each) do
    # Perilously use the build in list even though it is dynamic so we don't get warnings about the constant
    # HELP_TOPICS = [ "foo", "bar", "knife-kittens", "ceiling-cat", "shell" ]
    @knife = Chef::Knife::Help.new
  end

  it "should return a list of help topics" do
    expect(@knife.help_topics).to include("knife-status")
  end

  it "should run man for you" do
    @knife.name_args = [ "shell" ]
    expect(@knife).to receive(:exec).with(/^man \/.*\/shell.1$/)
    @knife.run
  end

  it "should suggest topics" do
    @knife.name_args = [ "list" ]
    allow(@knife.ui).to receive(:msg)
    expect(@knife.ui).to receive(:info).with("Available help topics are: ")
    expect(@knife.ui).to receive(:msg).with(/knife/)
    allow(@knife).to receive(:exec)
    expect(@knife).to receive(:exit).with(1)
    @knife.run
  end

  describe "find_manpage_path" do
    it "should find the man page in the gem" do
      expect(@knife.find_manpage_path("shell")).to match(/distro\/common\/man\/man1\/chef-shell.1$/)
    end

    it "should provide the man page name if not in the gem" do
      expect(@knife.find_manpage_path("foo")).to eq("foo")
    end
  end

  describe "find_manpages_for_query" do
    it "should error if it does not find a match" do
      allow(@knife.ui).to receive(:error)
      allow(@knife.ui).to receive(:info)
      allow(@knife.ui).to receive(:msg)
      expect(@knife).to receive(:exit).with(1)
      expect(@knife.ui).to receive(:error).with("No help found for 'chickens'")
      expect(@knife.ui).to receive(:msg).with(/knife/)
      @knife.find_manpages_for_query("chickens")
    end
  end

  describe "print_help_topics" do
    it "should print the known help topics" do
      allow(@knife.ui).to receive(:msg)
      allow(@knife.ui).to receive(:info)
      expect(@knife.ui).to receive(:msg).with(/knife/)
      @knife.print_help_topics
    end

    it "should shorten topics prefixed by knife-" do
      allow(@knife.ui).to receive(:msg)
      allow(@knife.ui).to receive(:info)
      expect(@knife.ui).to receive(:msg).with(/node/)
      @knife.print_help_topics
    end

    it "should not leave topics prefixed by knife-" do
      allow(@knife.ui).to receive(:msg)
      allow(@knife.ui).to receive(:info)
      expect(@knife.ui).not_to receive(:msg).with(/knife-node/)
      @knife.print_help_topics
    end
  end
end
