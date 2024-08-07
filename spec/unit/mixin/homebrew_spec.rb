#
# Author:: Joshua Timberman (<joshua@chef.io>)
#
# Copyright:: Copyright (c) Chef Software Inc.
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
require "chef/mixin/homebrew"

class ExampleHomebrew
  include Chef::Mixin::Homebrew
end

describe Chef::Mixin::Homebrew do
  let(:homebrew) { ExampleHomebrew.new }
  let(:node) { Chef::Node.new }

  describe "when the homebrew user is provided" do
    let(:uid) { 1001 }
    let(:user) { "foo" }

    it "returns the homebrew user without looking at the file when uid is provided" do
      expect(File).to receive(:exist?).exactly(0).times
      expect(homebrew.find_homebrew_uid(uid)).to eq(uid)
    end

    it "returns the homebrew user without looking at the file when name is provided" do
      expect(File).to receive(:exist?).exactly(0).times
      allow(Etc).to receive_message_chain(:getpwnam, :uid).and_return(uid)
      expect(homebrew.find_homebrew_uid(user)).to eq(uid)
    end

  end

  shared_examples "successfully find executable" do
    let(:user) { nil }
    let(:brew_owner) { 2001 }
    let(:default_brew_path) { "/usr/local/bin/brew" }
    let(:default_brew_path_arm) { "/opt/homebrew/bin/brew" }
    let(:default_brew_path_linux) { "/home/linuxbrew/.linuxbrew/bin/brew" }
    let(:stat_double) do
      d = double
      expect(d).to receive(:uid).and_return(brew_owner)
      d
    end

    context "debug statement prints owner name" do

      before do
        expect(Etc).to receive(:getpwuid).with(brew_owner).and_return(OpenStruct.new(name: "name"))
      end

      def false_unless_specific_value(object, method, value)
        allow(object).to receive(method).and_return(false)
        allow(object).to receive(method).with(value).and_return(true)
      end

      it "returns the owner of the brew executable when it is at a default location for x86_64 machines" do
        allow(File).to receive(:stat).with(default_brew_path).and_return(stat_double)
        expect(homebrew.find_homebrew_uid(user)).to eq(brew_owner)
      end

      it "returns the owner of the brew executable when it is at a default location for arm machines" do
        false_unless_specific_value(File, :exist?, default_brew_path_arm)
        false_unless_specific_value(File, :executable?, default_brew_path_arm)
        allow(File).to receive(:stat).with(default_brew_path_arm).and_return(stat_double)
        expect(homebrew.find_homebrew_uid(user)).to eq(brew_owner)
      end

      it "returns the owner of the brew executable when it is at a default location for linux machines" do
        false_unless_specific_value(File, :exist?, default_brew_path_linux)
        false_unless_specific_value(File, :executable?, default_brew_path_linux)
        allow(File).to receive(:stat).with(default_brew_path_linux).and_return(stat_double)
        expect(homebrew.find_homebrew_uid(user)).to eq(brew_owner)
      end

      it "returns the owner of the brew executable when it is not at a default location" do
        allow_any_instance_of(ExampleHomebrewUser).to receive(:which).and_return("/foo")
        false_unless_specific_value(File, :exist?, "/foo")
        false_unless_specific_value(File, :executable?, "/foo")
        allow(homebrew).to receive_message_chain(:shell_out, :stdout, :strip).and_return("/foo")
        allow(File).to receive(:stat).with("/foo").and_return(stat_double)
        expect(homebrew.find_homebrew_uid(user)).to eq(brew_owner)
      end

    end
  end

  describe "when the homebrew user is not provided" do

    it "raises an error if no executable is found" do
      allow_any_instance_of(ExampleHomebrew).to receive(:which).and_return(false)
      expect { homebrew.homebrew_bin_path }.to raise_error(Chef::Exceptions::CannotDetermineHomebrewPath)
    end

    include_examples "successfully find executable"

    context "the executable is owned by root" do
      include_examples "successfully find executable" do
        let(:brew_owner) { 0 }
      end
    end

  end

end
