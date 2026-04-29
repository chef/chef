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

RSpec.describe TargetIO::TrainCompat::Dir do
  let(:new_dir) { "/new/dir" }
  let(:old_dir) { "/old/dir" }

  let(:cmd_ok) { double("cmd_result", exit_status: 0, stdout: "", stderr: "") }

  let(:transport_connection) do
    double("transport_connection",
      transport_options: { sudo: false, user: "ubuntu" })
  end

  before do
    run_ctx = double("run_context", transport_connection: transport_connection)
    allow(Chef).to receive(:run_context).and_return(run_ctx)
    allow(transport_connection).to receive(:run_command).and_return(cmd_ok)
    allow(transport_connection).to receive(:upload)
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".entries" do
    it "returns directory entries via ls -1a" do
      allow(transport_connection).to receive(:run_command)
        .with("ls -1a /etc").and_return(double(stdout: ".\n..\nhosts\npasswd\n"))
      expect(described_class.entries("/etc")).to eq([".", "..", "hosts", "passwd"])
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".mkdir" do
    it "creates the directory" do
      expect(TargetIO::FileUtils).to receive(:mkdir).with(new_dir)
      described_class.mkdir(new_dir)
    end

    it "sets mode when provided" do
      expect(TargetIO::FileUtils).to receive(:mkdir).with(new_dir)
      expect(TargetIO::FileUtils).to receive(:chmod).with(new_dir, 0o755)
      described_class.mkdir(new_dir, 0o755)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".unlink" do
    it "removes the directory" do
      expect(TargetIO::FileUtils).to receive(:rmdir).with(old_dir)
      described_class.unlink(old_dir)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".delete" do
    it "recursively removes the directory" do
      expect(TargetIO::FileUtils).to receive(:rm_rf).with(old_dir)
      described_class.delete(old_dir)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".directory?" do
    it "delegates to TargetIO::File.directory?" do
      expect(TargetIO::File).to receive(:directory?).with("/etc").and_return(true)
      expect(described_class.directory?("/etc")).to be true
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".tmpdir" do
    it "returns the local temp directory" do
      expect(described_class.tmpdir).to eq(::Dir.tmpdir)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".mktmpdir" do
    before do
      allow(TargetIO::FileUtils).to receive(:mkdir)
      allow(TargetIO::FileUtils).to receive(:chmod)
      allow(TargetIO::FileUtils).to receive(:chown)
      allow(TargetIO::FileUtils).to receive(:rm_rf) # at_exit cleanup
    end

    it "creates a temporary directory and returns its path string" do
      path = described_class.mktmpdir("chef-test")
      expect(path).to be_a(String)
      expect(path).not_to be_empty
    end

    it "sets permissions to 0700" do
      expect(TargetIO::FileUtils).to receive(:chmod).with(0o700, anything)
      described_class.mktmpdir("chef-test")
    end

    it "uses the supplied prefix in the generated directory name" do
      path = described_class.mktmpdir("myprefix")
      expect(path).to include("myprefix")
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".glob" do
    it "executes a bash globstar command on the remote target" do
      output = double(stdout: "foo.rb\nbar.rb\n")
      expect(transport_connection).to receive(:run_command).with(/shopt -s globstar/).and_return(output)
      result = described_class.glob("*.rb")
      # Results are sorted by default
      expect(result).to eq(%w{bar.rb foo.rb})
    end

    it "returns results in sorted order by default" do
      output = double(stdout: "z.rb\na.rb\nm.rb\n")
      allow(transport_connection).to receive(:run_command).with(any_args).and_return(output)
      expect(described_class.glob("*.rb")).to eq(%w{a.rb m.rb z.rb})
    end

    it "raises for unsupported glob flags" do
      expect { described_class.glob("*.rb", ::File::FNM_CASEFOLD) }
        .to raise_error(RuntimeError, /not supported/)
    end
  end
end
