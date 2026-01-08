#
# Author:: Joshua Timberman (<joshua@chef.io>)
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

describe Chef::Mixin::Homebrew do
  let(:homebrew) { Class.new { include Chef::Mixin::Homebrew }.new }
  let(:uid) { 1001 }
  let(:username) { "foobar" }
  let(:alt_brew_path) { "/foo" }

  describe "#find_homebrew_uid" do
    it "returns the provided UID when an integer is given" do
      expect(File).to receive(:exist?).exactly(0).times
      expect(homebrew.find_homebrew_uid(uid)).to eq(uid)
    end

    it "returns the provided UID when username is given" do
      expect(File).to receive(:exist?).exactly(0).times
      allow(Etc).to receive(:getpwnam).with(username).and_return(OpenStruct.new(uid: uid))
      expect(homebrew.find_homebrew_uid(username)).to eq(uid)
    end

    it "raises an error when the brew executable is not found" do
      allow(homebrew).to receive(:homebrew_bin_path).and_raise(Chef::Exceptions::CannotDetermineHomebrewPath)
      expect { homebrew.find_homebrew_uid }.to raise_error(Chef::Exceptions::CannotDetermineHomebrewPath)
    end

    it "returns the UID of the owner based on the brew executable" do
      allow(homebrew).to receive(:homebrew_bin_path).and_return(alt_brew_path)
      allow(File).to receive(:stat).with(alt_brew_path).and_return(OpenStruct.new(uid: uid))
      allow(Etc).to receive(:getpwuid).with(uid).and_return(OpenStruct.new(name: username))
      expect(homebrew.find_homebrew_uid).to eq(uid)
    end
  end

  describe "#find_homebrew_username" do
    it "returns the username for the provided UID" do
      allow(homebrew).to receive(:find_homebrew_uid).and_return(uid)
      allow(Etc).to receive(:getpwuid).with(uid).and_return(OpenStruct.new(name: username))
      expect(homebrew.find_homebrew_username(uid)).to eq(username)
    end
  end

  describe "#homebrew_bin_path" do
    it "returns the correct path when a valid path is provided" do
      allow(File).to receive(:exist?).with(alt_brew_path).and_return(true)
      expect(homebrew.homebrew_bin_path(alt_brew_path)).to eq(alt_brew_path)
    end

    it "raises an error when the brew executable is not found" do
      allow(homebrew).to receive(:which).and_return(false)
      expect { homebrew.homebrew_bin_path }.to raise_error(Chef::Exceptions::CannotDetermineHomebrewPath)
    end
  end

  shared_examples "successfully find executable" do
    let(:default_brew_path) { "/usr/local/bin/brew" }
    let(:default_brew_path_arm) { "/opt/homebrew/bin/brew" }
    let(:default_brew_path_linux) { "/home/linuxbrew/.linuxbrew/bin/brew" }

    context "debug statement prints owner name" do

      before do
        expect(Etc).to receive(:getpwuid).with(uid).and_return(OpenStruct.new(name: username))
      end

      it "returns the owner of the brew executable when it is at a default location for x86_64 machines" do
        allow(homebrew).to receive(:homebrew_bin_path).and_return(default_brew_path)
        allow(File).to receive(:stat).with(default_brew_path).and_return(OpenStruct.new(uid: uid))
        expect(homebrew.find_homebrew_uid).to eq(uid)
      end

      it "returns the owner of the brew executable when it is at a default location for arm machines" do
        allow(homebrew).to receive(:homebrew_bin_path).and_return(default_brew_path_arm)
        allow(File).to receive(:stat).with(default_brew_path_arm).and_return(OpenStruct.new(uid: uid))
        expect(homebrew.find_homebrew_uid).to eq(uid)
      end

      it "returns the owner of the brew executable when it is at a default location for linux machines" do
        allow(homebrew).to receive(:homebrew_bin_path).and_return(default_brew_path_linux)
        allow(File).to receive(:stat).with(default_brew_path_linux).and_return(OpenStruct.new(uid: uid))
        expect(homebrew.find_homebrew_uid).to eq(uid)
      end

      it "returns the owner of the brew executable when it is not at a default location" do
        allow(homebrew).to receive(:homebrew_bin_path).and_return(alt_brew_path)
        allow(File).to receive(:stat).with(alt_brew_path).and_return(OpenStruct.new(uid: uid))
        expect(homebrew.find_homebrew_uid).to eq(uid)
      end
    end
  end

  describe "#When the homebrew user is not provided" do

    include_examples "successfully find executable"

    context "the executable is owned by root" do
      include_examples "successfully find executable" do
        let(:uid) { 0 }
      end
    end
  end
end
