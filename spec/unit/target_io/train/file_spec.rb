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

RSpec.describe TargetIO::TrainCompat::File do
  let(:hosts_path) { "/etc/hosts" }
  let(:file_content) { "line1\nline2\nline3" }

  let(:train_file) do
    double("train_file",
      content:       file_content,
      exist?:        true,
      directory?:    false,
      size:          file_content.bytesize,
      mode:          0o644,
      owner:         "root",
      group:         "root",
      mtime:         1_700_000_000,
      selinux_label: nil,
      stat: {
        mode: 0o644, size: file_content.bytesize,
        owner: "root", group: "root", mtime: 1_700_000_000,
        uid: 0, gid: 0
      })
  end

  let(:cmd_ok) { double("cmd_result", exit_status: 0, stdout: "", stderr: "") }

  let(:transport_connection) do
    double("transport_connection",
      transport_options: { sudo: false, user: "ubuntu" })
  end

  before do
    run_ctx = double("run_context", transport_connection: transport_connection)
    allow(Chef).to receive(:run_context).and_return(run_ctx)
    allow(transport_connection).to receive(:file).with(any_args).and_return(train_file)
    allow(transport_connection).to receive(:run_command).and_return(cmd_ok)
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".read" do
    it "returns file contents joined with newlines" do
      expect(described_class.read(hosts_path)).to eq(file_content)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".readlines" do
    it "splits content into an array of lines" do
      expect(described_class.readlines(hosts_path)).to eq(%w{line1 line2 line3})
    end

    context "when the file does not exist" do
      before { allow(train_file).to receive(:content).and_return(nil) }

      it "raises Errno::ENOENT" do
        expect { described_class.readlines("/nonexistent") }.to raise_error(Errno::ENOENT)
      end
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".foreach" do
    it "yields each line when a block is given" do
      lines = []
      described_class.foreach(hosts_path) { |l| lines << l }
      expect(lines).to eq(%w{line1 line2 line3})
    end

    it "raises when called without a block" do
      expect { described_class.foreach(hosts_path) }.to raise_error(RuntimeError, /block/)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".binread" do
    it "returns the full content when no length is given" do
      expect(described_class.binread(hosts_path)).to eq(file_content)
    end

    it "returns a slice when length and offset are given" do
      expect(described_class.binread(hosts_path, 5, 0)).to eq("line1")
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".expand_path" do
    it "collapses relative path segments" do
      result = described_class.expand_path("../bar", "/foo")
      expect(result.to_s).to eq("/bar")
    end

    it "returns an absolute path for a bare filename" do
      result = described_class.expand_path("hosts", "/etc")
      expect(result.to_s).to eq(hosts_path)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".executable?" do
    it "returns true when any execute bit is set (0755)" do
      allow(transport_connection).to receive(:file).with("/bin/bash").and_return(
        double("file", stat: { mode: 0o755 })
      )
      expect(described_class.executable?("/bin/bash")).to be true
    end

    it "returns false when no execute bit is set (0644)" do
      allow(transport_connection).to receive(:file).with(hosts_path).and_return(
        double("file", stat: { mode: 0o644 })
      )
      expect(described_class.executable?(hosts_path)).to be false
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".readable?" do
    it "returns true when test -r exits 0" do
      allow(transport_connection).to receive(:run_command)
        .with("test -r /etc/hosts").and_return(double(exit_status: 0))
      expect(described_class.readable?(hosts_path)).to be true
    end

    it "returns false when test -r exits non-zero" do
      allow(transport_connection).to receive(:run_command)
        .with("test -r /root/secret").and_return(double(exit_status: 1))
      expect(described_class.readable?("/root/secret")).to be false
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".writable?" do
    it "returns true when test -w exits 0" do
      allow(transport_connection).to receive(:run_command)
        .with("test -w /tmp/writable").and_return(double(exit_status: 0))
      expect(described_class.writable?("/tmp/writable")).to be true
    end

    it "returns false when test -w exits non-zero" do
      allow(transport_connection).to receive(:run_command)
        .with("test -w /etc/shadow").and_return(double(exit_status: 1))
      expect(described_class.writable?("/etc/shadow")).to be false
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".realpath" do
    it "returns the resolved path via the realpath command" do
      allow(transport_connection).to receive(:run_command)
        .with("realpath /var/log").and_return(double(stdout: "/private/var/log\n"))
      expect(described_class.realpath("/var/log")).to eq("/private/var/log")
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".readlink" do
    let(:symlink_path) { "/etc/alternatives/ruby" }

    before do
      allow(train_file).to receive(:symlink?).and_return(true)
      allow(transport_connection).to receive(:file).with(symlink_path).and_return(train_file)
      allow(transport_connection).to receive(:run_command)
        .with("readlink #{symlink_path}")
        .and_return(double(stdout: "/usr/bin/ruby3.0\n"))
    end

    it "returns the symlink target" do
      expect(described_class.readlink(symlink_path)).to eq("/usr/bin/ruby3.0")
    end

    context "when path is not a symlink" do
      before { allow(train_file).to receive(:symlink?).and_return(false) }

      it "raises Errno::EINVAL" do
        expect { described_class.readlink(symlink_path) }.to raise_error(Errno::EINVAL)
      end
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".open (read mode)" do
    it "yields a StringIO containing the file content" do
      yielded_content = nil
      described_class.open(hosts_path, "r") { |io| yielded_content = io.read }
      expect(yielded_content).to include("line1")
    end

    it "truncates content in write mode before yielding" do
      allow(transport_connection).to receive(:upload)
      described_class.open(hosts_path, "w") { |io| expect(io.string).to eq("") }
    end

    it "raises for block-less open with non-read modes" do
      expect { described_class.open(hosts_path, "w") }.to raise_error(RuntimeError)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".stat" do
    it "returns an OpenStruct from train file stat data" do
      allow(transport_connection).to receive(:file).with(hosts_path, true).and_return(train_file)
      result = described_class.stat(hosts_path)
      expect(result.mode).to eq(0o644)
      expect(result.owner).to eq("root")
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".method_missing - non-IO passthrough (to ::File)" do
    let(:ruby_file) { "/foo/bar.rb" }

    it "delegates :basename to ::File" do
      expect(described_class.basename(ruby_file)).to eq("bar.rb")
    end

    it "delegates :join to ::File" do
      expect(described_class.join("/foo", "bar")).to eq("/foo/bar")
    end

    it "delegates :dirname to ::File" do
      expect(described_class.dirname(ruby_file)).to eq("/foo")
    end

    it "delegates :extname to ::File" do
      expect(described_class.extname(ruby_file)).to eq(".rb")
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".method_missing - Train file passthrough" do
    it "delegates :exist? to the train file object" do
      allow(transport_connection).to receive(:file).with(hosts_path).and_return(
        double("file", exist?: true)
      )
      expect(described_class.exist?(hosts_path)).to be true
    end

    it "delegates :directory? to the train file object" do
      allow(transport_connection).to receive(:file).with("/etc").and_return(
        double("file", directory?: true)
      )
      expect(described_class.directory?("/etc")).to be true
    end

    it "delegates :symlink? to the train file object" do
      allow(transport_connection).to receive(:file).with("/link").and_return(
        double("file", symlink?: true)
      )
      expect(described_class.symlink?("/link")).to be true
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".method_missing - unsupported method" do
    it "raises RuntimeError listing the method name" do
      expect { described_class.nonexistent_method("/foo") }.to raise_error(RuntimeError, /Unsupported File method/)
    end
  end
end
