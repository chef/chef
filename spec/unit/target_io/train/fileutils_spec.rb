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

RSpec.describe TargetIO::TrainCompat::FileUtils do
  NOOP_SKIP_EXAMPLE = "skips execution when noop: true".freeze

  let(:tmp_file) { "/tmp/file" }
  let(:cmd_ok) { double("cmd_result", exit_status: 0, stdout: "", stderr: "") }

  let(:transport_connection) do
    double("transport_connection",
      transport_options: { sudo: false, user: "ubuntu" })
  end

  before do
    run_ctx = double("run_context", transport_connection: transport_connection)
    allow(Chef).to receive(:run_context).and_return(run_ctx)
    allow(transport_connection).to receive(:run_command).and_return(cmd_ok)
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".chmod" do
    it "runs chmod with octal mode" do
      expect(transport_connection).to receive(:run_command).with("chmod 755 /bin/script")
      described_class.chmod(0o755, "/bin/script")
    end

    it "accepts an array of paths" do
      expect(transport_connection).to receive(:run_command).with("chmod 644 /a /b")
      described_class.chmod(0o644, ["/a", "/b"])
    end

    it NOOP_SKIP_EXAMPLE do
      expect(transport_connection).not_to receive(:run_command)
      described_class.chmod(0o755, "/bin/script", noop: true)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".chown" do
    let(:app_path) { "/etc/app" }

    it "runs chown with user and group" do
      expect(transport_connection).to receive(:run_command).with("chown alice:staff #{app_path}")
      described_class.chown("alice", "staff", app_path)
    end

    it "omits group when nil" do
      expect(transport_connection).to receive(:run_command).with("chown alice #{app_path}")
      described_class.chown("alice", nil, app_path)
    end

    it "omits user when nil" do
      expect(transport_connection).to receive(:run_command).with("chown :staff #{app_path}")
      described_class.chown(nil, "staff", app_path)
    end

    it NOOP_SKIP_EXAMPLE do
      expect(transport_connection).not_to receive(:run_command)
      described_class.chown("alice", "staff", app_path, noop: true)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".cp" do
    it "copies without preserve flag by default" do
      expect(transport_connection).to receive(:run_command).with("cp /src /dest")
      described_class.cp("/src", "/dest")
    end

    it "uses -p flag when preserve: true" do
      expect(transport_connection).to receive(:run_command).with("cp -p /src /dest")
      described_class.cp("/src", "/dest", preserve: true)
    end

    it NOOP_SKIP_EXAMPLE do
      expect(transport_connection).not_to receive(:run_command)
      described_class.cp("/src", "/dest", noop: true)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".cp_r" do
    it "copies recursively" do
      expect(transport_connection).to receive(:run_command).with("cp -r /src /dest")
      described_class.cp_r("/src", "/dest")
    end

    it "preserves attributes when preserve: true" do
      expect(transport_connection).to receive(:run_command).with("cp -rp /src /dest")
      described_class.cp_r("/src", "/dest", preserve: true)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".mv" do
    it "moves without force flag by default" do
      expect(transport_connection).to receive(:run_command).with("mv /src /dest")
      described_class.mv("/src", "/dest")
    end

    it "uses -f flag when force: true" do
      expect(transport_connection).to receive(:run_command).with("mv -f /src /dest")
      described_class.mv("/src", "/dest", force: true)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".rm" do
    it "removes a file" do
      expect(transport_connection).to receive(:run_command).with("rm #{tmp_file}")
      described_class.rm(tmp_file)
    end

    it "accepts an array of paths" do
      expect(transport_connection).to receive(:run_command).with("rm /a /b")
      described_class.rm(["/a", "/b"])
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".rm_rf" do
    it "runs rm -rf" do
      expect(transport_connection).to receive(:run_command).with("rm -rf /tmp/dir")
      described_class.rm_rf("/tmp/dir")
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".mkdir" do
    it "creates a directory" do
      expect(transport_connection).to receive(:run_command).with("mkdir /new/dir")
      described_class.mkdir("/new/dir")
    end

    it "sets mode when provided" do
      expect(transport_connection).to receive(:run_command).with("mkdir -m 750 /new/dir")
      described_class.mkdir("/new/dir", mode: 0o750)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".mkdir_p" do
    it "creates parent directories with -p" do
      expect(transport_connection).to receive(:run_command).with("mkdir -p /new/deep/dir")
      described_class.mkdir_p("/new/deep/dir")
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".ln_s" do
    it "creates a symlink" do
      expect(transport_connection).to receive(:run_command).with("ln -s /src /link")
      described_class.ln_s("/src", "/link")
    end

    it "uses -sf flag when force: true" do
      expect(transport_connection).to receive(:run_command).with("ln -sf /src /link")
      described_class.ln_s("/src", "/link", force: true)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".ln" do
    it "creates a hard link" do
      expect(transport_connection).to receive(:run_command).with("ln /src /link")
      described_class.ln("/src", "/link")
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".touch" do
    it "touches a file" do
      expect(transport_connection).to receive(:run_command).with("touch #{tmp_file}")
      described_class.touch([tmp_file])
    end

    it "accepts nocreate option" do
      expect(transport_connection).to receive(:run_command).with("touch -c #{tmp_file}")
      described_class.touch([tmp_file], nocreate: true)
    end

    it NOOP_SKIP_EXAMPLE do
      expect(transport_connection).not_to receive(:run_command)
      described_class.touch([tmp_file], noop: true)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".install" do
    let(:install_src) { "/src/file" }
    let(:install_dst) { "/usr/local/bin/file" }

    it "runs install command" do
      expect(transport_connection).to receive(:run_command).with(/^install -c /)
      described_class.install(install_src, install_dst)
    end

    it "includes mode when specified" do
      expect(transport_connection).to receive(:run_command).with(/install -c -m 755/)
      described_class.install(install_src, install_dst, mode: 0o755)
    end

    it "includes owner when specified" do
      expect(transport_connection).to receive(:run_command).with(/install -c -o root/)
      described_class.install(install_src, install_dst, owner: "root")
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe ".method_missing (unsupported)" do
    it "raises RuntimeError listing the method name" do
      expect { described_class.nonexistent_op("/foo") }.to raise_error(RuntimeError, /Unsupported/)
    end
  end
end
