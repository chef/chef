# frozen_string_literal: true
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# Copyright:: Copyright (c) 2026 Tim Smith
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

RSpec.describe ChefUtils::DSL::TrainHelpers do
  class TrainHelpersTestClass
    include ChefUtils::DSL::TrainHelpers
  end

  let(:test) { TrainHelpersTestClass.new }

  context "without a transport connection" do
    before do
      allow(test).to receive(:__transport_connection).and_return(nil)
    end

    it "file_exist? checks the local file" do
      expect(File).to receive(:exist?).with("/etc/os-release").and_return(true)
      expect(test.file_exist?("/etc/os-release")).to be true
    end

    it "file_read reads the local file" do
      expect(File).to receive(:open).with("/etc/hostname").and_return(StringIO.new("web01\n"))
      expect(test.file_read("/etc/hostname")).to eq("web01\n")
    end

    it "file_directory? checks the local path" do
      expect(File).to receive(:directory?).with("/etc").and_return(true)
      expect(test.file_directory?("/etc")).to be true
    end

    it "dir_exist? checks the local path" do
      expect(File).to receive(:directory?).with("/missing").and_return(false)
      expect(test.dir_exist?("/missing")).to be false
    end
  end

  context "with a transport connection" do
    let(:remote_file) { double("Train::File", exist?: true, directory?: true, content: "web01\n") }
    let(:connection) { double("Train::Transports::SSH::Connection") }

    before do
      allow(test).to receive(:__transport_connection).and_return(connection)
      allow(connection).to receive(:file).and_return(remote_file)
    end

    it "file_exist? asks the remote file" do
      expect(connection).to receive(:file).with("/etc/os-release").and_return(remote_file)
      expect(test.file_exist?("/etc/os-release")).to be true
    end

    it "file_read reads the remote file" do
      expect(connection).to receive(:file).with("/etc/hostname").and_return(remote_file)
      expect(test.file_read("/etc/hostname")).to eq("web01\n")
    end

    it "file_directory? asks the remote path" do
      expect(connection).to receive(:file).with("/etc").and_return(remote_file)
      expect(test.file_directory?("/etc")).to be true
    end

    it "dir_exist? asks the remote path" do
      expect(connection).to receive(:file).with("C:\\WindowsAzure").and_return(double("Train::File", directory?: false))
      expect(test.dir_exist?("C:\\WindowsAzure")).to be false
    end
  end
end
