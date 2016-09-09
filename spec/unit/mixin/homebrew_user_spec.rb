#
# Author:: Joshua Timberman (<joshua@chef.io>)
#
# Copyright 2014-2016, Chef Software, Inc <legal@chef.io>
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

require "spec_helper"
require "chef/mixin/homebrew_user"

class ExampleHomebrewUser
  include Chef::Mixin::HomebrewUser
end

describe Chef::Mixin::HomebrewUser do
  before(:each) do
    node.default["homebrew"]["owner"] = nil
  end

  let(:homebrew_user) { ExampleHomebrewUser.new }
  let(:node) { Chef::Node.new }

  describe "when the homebrew user is provided" do
    let(:uid) { 1001 }
    let(:user) { "foo" }

    it "returns the homebrew user without looking at the file when uid is provided" do
      expect(File).to receive(:exist?).exactly(0).times
      expect(homebrew_user.find_homebrew_uid(uid)).to eq(uid)
    end

    it "returns the homebrew user without looking at the file when name is provided" do
      expect(File).to receive(:exist?).exactly(0).times
      allow(Etc).to receive_message_chain(:getpwnam, :uid).and_return(uid)
      expect(homebrew_user.find_homebrew_uid(user)).to eq(uid)
    end

  end

  shared_examples "successfully find executable" do
    let(:user) { nil }
    let(:brew_owner) { 2001 }
    let(:default_brew_path) { "/usr/local/bin/brew" }
    let(:stat_double) do
      d = double()
      expect(d).to receive(:uid).and_return(brew_owner)
      d
    end

    context "debug statement prints owner name" do

      before do
        expect(Etc).to receive(:getpwuid).with(brew_owner).and_return(OpenStruct.new(:name => "name"))
      end

      it "returns the owner of the brew executable when it is at a default location" do
        expect(File).to receive(:exist?).with(default_brew_path).and_return(true)
        expect(File).to receive(:stat).with(default_brew_path).and_return(stat_double)
        expect(homebrew_user.find_homebrew_uid(user)).to eq(brew_owner)
      end

      it "returns the owner of the brew executable when it is not at a default location" do
        expect(File).to receive(:exist?).with(default_brew_path).and_return(false)
        allow(homebrew_user).to receive_message_chain(:shell_out, :stdout, :strip).and_return("/foo")
        expect(File).to receive(:stat).with("/foo").and_return(stat_double)
        expect(homebrew_user.find_homebrew_uid(user)).to eq(brew_owner)
      end

    end
  end

  describe "when the homebrew user is not provided" do

    it "raises an error if no executable is found" do
      expect(File).to receive(:exist?).with(default_brew_path).and_return(false)
      allow(homebrew_user).to receive_message_chain(:shell_out, :stdout, :strip).and_return("")
      expect { homebrew_user.find_homebrew_uid(user) }.to raise_error(Chef::Exceptions::CannotDetermineHomebrewOwner)
    end

    include_examples "successfully find executable"

    context "the executable is owned by root" do
      include_examples "successfully find executable" do
        let(:brew_owner) { 0 }
      end
    end

  end

end
