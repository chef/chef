#
# Copyright:: Copyright (c) 2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require "spec_helper"
require "chef/target_io"

# Minimal class that exercises the TargetIO::Support mixin.
class TargetIOSupportTestHelper
  include TargetIO::Support
end

RSpec.describe TargetIO::Support do
  let(:file_content) { "hello world" }
  let(:remote_path)  { "/remote/path" }
  let(:remote_file)  { "/remote/file" }
  let(:local_file)   { "/local/file" }

  subject(:helper) { TargetIOSupportTestHelper.new }

  let(:transport_connection) do
    double("transport_connection",
      transport_options: { sudo: false, user: "ubuntu" })
  end

  before do
    run_ctx = double("run_context", transport_connection: transport_connection)
    allow(Chef).to receive(:run_context).and_return(run_ctx)
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe "#transport_connection" do
    it "returns the connection from Chef.run_context" do
      expect(helper.transport_connection).to eq(transport_connection)
    end

    context "when run_context is nil" do
      before { allow(Chef).to receive(:run_context).and_return(nil) }

      it "returns nil" do
        expect(helper.transport_connection).to be_nil
      end
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe "#sudo?" do
    it "returns false when sudo option is false" do
      expect(helper.sudo?).to be false
    end

    context "when sudo is enabled" do
      let(:transport_connection) do
        double("transport_connection",
          transport_options: { sudo: true, user: "root" })
      end

      it "returns true" do
        expect(helper.sudo?).to be true
      end
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe "#remote_user" do
    it "returns the user from transport options" do
      expect(helper.remote_user).to eq("ubuntu")
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe "#run_command" do
    it "delegates to transport_connection.run_command" do
      result = double("cmd_result", exit_status: 0, stdout: "output\n")
      expect(transport_connection).to receive(:run_command).with("ls -la /tmp").and_return(result)
      expect(helper.run_command("ls -la /tmp")).to eq(result)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe "#read_file" do
    let(:train_file) { double("train_file", content: file_content) }

    context "without sudo" do
      before do
        allow(transport_connection).to receive(:file).with(remote_path).and_return(train_file)
      end

      it "reads the file directly via transport" do
        expect(helper.read_file(remote_path)).to eq(file_content)
      end

      it "does not stage the file" do
        expect(::TargetIO::FileUtils).not_to receive(:cp)
        helper.read_file(remote_path)
      end
    end

    context "with sudo" do
      let(:transport_connection) do
        double("transport_connection",
          transport_options: { sudo: true, user: "root" })
      end
      let(:staged_path) { "/tmp/chef_staging_dir/path" }

      before do
        allow(::TargetIO::Dir).to receive(:mktmpdir).and_return("/tmp/chef_staging_dir")
        allow(::TargetIO::FileUtils).to receive(:cp)
        allow(::TargetIO::FileUtils).to receive(:rm)
        allow(::TargetIO::FileUtils).to receive(:rmdir)
        allow(transport_connection).to receive(:file).with(staged_path).and_return(train_file)
      end

      it "copies the file to a staging path before reading" do
        expect(::TargetIO::FileUtils).to receive(:cp).with(remote_path, staged_path)
        helper.read_file(remote_path)
      end

      it "returns the file content" do
        expect(helper.read_file(remote_path)).to eq(file_content)
      end

      it "cleans up the staging area after reading" do
        expect(::TargetIO::FileUtils).to receive(:rm).with(staged_path)
        helper.read_file(remote_path)
      end
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe "#write_file" do
    before do
      allow(transport_connection).to receive(:upload)
      # Dir.mktmpdir used by staging_file called from upload when sudo
      allow(::TargetIO::Dir).to receive(:mktmpdir).and_return("/tmp/staging")
      allow(::TargetIO::FileUtils).to receive(:mv)
      allow(::TargetIO::FileUtils).to receive(:rm)
      allow(::TargetIO::FileUtils).to receive(:rmdir)
    end

    it "uploads the content to the remote file" do
      expect(transport_connection).to receive(:upload).with(anything, remote_file)
      helper.write_file(remote_file, "new content")
    end

    it "returns the remote file path" do
      expect(helper.write_file(remote_file, "content")).to eq(remote_file)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe "#upload" do
    context "without sudo" do
      it "uploads directly to the target path" do
        expect(transport_connection).to receive(:upload).with(local_file, remote_file)
        helper.upload(local_file, remote_file)
      end
    end

    context "with sudo" do
      let(:transport_connection) do
        double("transport_connection",
          transport_options: { sudo: true, user: "root" })
      end

      before do
        allow(::TargetIO::Dir).to receive(:mktmpdir).and_return("/tmp/staging_dir")
        allow(transport_connection).to receive(:upload)
        allow(::TargetIO::FileUtils).to receive(:mv)
        allow(::TargetIO::FileUtils).to receive(:rm)
        allow(::TargetIO::FileUtils).to receive(:rmdir)
        allow(::TargetIO::FileUtils).to receive(:chown)
      end

      it "uploads to a staging path first" do
        expect(transport_connection).to receive(:upload).with(local_file, /staging_dir/)
        helper.upload(local_file, remote_file)
      end

      it "moves the staging file to the final destination" do
        expect(::TargetIO::FileUtils).to receive(:mv).with(/staging_dir/, remote_file)
        helper.upload(local_file, remote_file)
      end

      it "cleans up the staging area" do
        expect(::TargetIO::FileUtils).to receive(:rm)
        helper.upload(local_file, remote_file)
      end
    end
  end
end
