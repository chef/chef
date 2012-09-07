#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'spec_helper'

describe Chef::Knife::Help do
  before(:each) do
    # Perilously use the build in list even though it is dynamic so we don't get warnings about the constant
    # HELP_TOPICS = [ "foo", "bar", "knife-kittens", "ceiling-cat", "shell" ]
    @knife = Chef::Knife::Help.new
  end

  it "should return a list of help topics" do
    @knife.help_topics.should include("knife-status")
  end

  it "should run man for you" do
    @knife.name_args = [ "shell" ]
    @knife.should_receive(:exec).with(/^man \/.*\/shell.1$/)
    @knife.run
  end

  it "should suggest topics" do
    @knife.name_args = [ "list" ]
    @knife.ui.stub!(:msg)
    @knife.ui.should_receive(:info).with("Available help topics are: ")
    @knife.ui.should_receive(:msg).with(/knife/)
    @knife.stub!(:exec)
    @knife.should_receive(:exit).with(1)
    @knife.run
  end

  describe "find_manpage_path" do
    it "should find the man page in the gem" do
      @knife.find_manpage_path("shell").should =~ /distro\/common\/man\/man1\/chef-shell.1$/
    end

    it "should provide the man page name if not in the gem" do
      @knife.find_manpage_path("foo").should == "foo"
    end
  end

  describe "find_manpages_for_query" do
    it "should error if it does not find a match" do
      @knife.ui.stub!(:error)
      @knife.ui.stub!(:info)
      @knife.ui.stub!(:msg)
      @knife.should_receive(:exit).with(1)
      @knife.ui.should_receive(:error).with("No help found for 'chickens'")
      @knife.ui.should_receive(:msg).with(/knife/)
      @knife.find_manpages_for_query("chickens")
    end
  end

  describe "print_help_topics" do
    it "should print the known help topics" do
      @knife.ui.stub!(:msg)
      @knife.ui.stub!(:info)
      @knife.ui.should_receive(:msg).with(/knife/)
      @knife.print_help_topics
    end

    it "should shorten topics prefixed by knife-" do
      @knife.ui.stub!(:msg)
      @knife.ui.stub!(:info)
      @knife.ui.should_receive(:msg).with(/node/)
      @knife.print_help_topics
    end

    it "should not leave topics prefixed by knife-" do
      @knife.ui.stub!(:msg)
      @knife.ui.stub!(:info)
      @knife.ui.should_not_receive(:msg).with(/knife-node/)
      @knife.print_help_topics
    end
  end
end
