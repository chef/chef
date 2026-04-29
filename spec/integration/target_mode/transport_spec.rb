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
#
# Integration tests for the Train transport layer used by target-mode.
#
# These tests are gated by TM_INTEGRATION_ENABLED=true and are only run by the
# target_mode_integration CI workflow.  They exercise real SSH and WinRM
# connections to containers / hosts set up by the workflow rather than using
# doubles or stubs.
#
# Environment variables consumed:
#   TM_INTEGRATION_ENABLED  – must be "true" to run any example
#
#   SSH targets (Linux containers):
#     TM_SSH_HOST_1  / TM_SSH_PORT_1  – first SSH target  (default 127.0.0.1 / 2222)
#     TM_SSH_HOST_2  / TM_SSH_PORT_2  – second SSH target (default 127.0.0.1 / 2223)
#     TM_SSH_USER                      – SSH login user     (default "root")
#     TM_SSH_KEY_FILE                  – path to private key (default /tmp/id_test)
#
#   WinRM target (Windows host / container):
#     TM_WINRM_HOST     – hostname / IP  (required to enable WinRM examples)
#     TM_WINRM_PORT     – WinRM port     (default 5985)
#     TM_WINRM_USER     – WinRM user     (required)
#     TM_WINRM_PASSWORD – WinRM password (required)

require "spec_helper"
require "train"

INTEGRATION_ENABLED = ENV["TM_INTEGRATION_ENABLED"] == "true" unless defined?(INTEGRATION_ENABLED)

RSpec.describe "Target Mode Transport Integration", :integration do

  before do
    skip "Set TM_INTEGRATION_ENABLED=true to run transport integration tests" unless INTEGRATION_ENABLED
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Shared behaviour – any working transport should satisfy these examples.
  # ─────────────────────────────────────────────────────────────────────────────
  shared_examples "a working Train transport" do |protocol|
    it "opens a connection without raising" do
      conn = nil
      expect { conn = transport.connection }.not_to raise_error
      conn&.close
    end

    it "runs a trivial command and receives exit status 0" do
      conn = transport.connection
      cmd  = conn.run_command(ping_command)
      conn.close
      expect(cmd.exit_status).to eq(0), \
        "Command '#{ping_command}' failed.\nSTDOUT: #{cmd.stdout}\nSTDERR: #{cmd.stderr}"
    end

    it "detects the target platform via Train" do
      conn     = transport.connection
      platform = conn.platform
      conn.close
      expect(platform.name).not_to be_nil
      expect(platform.name).not_to be_empty
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # SSH – Linux container 1
  # ─────────────────────────────────────────────────────────────────────────────
  context "SSH transport to Linux target 1" do
    before { skip "TM_SSH_HOST_1 not configured" unless ENV["TM_SSH_HOST_1"] }

    let(:transport) do
      Train.create("ssh",
        host:            ENV.fetch("TM_SSH_HOST_1", "127.0.0.1"),
        port:            ENV.fetch("TM_SSH_PORT_1", "2222").to_i,
        user:            ENV.fetch("TM_SSH_USER", "root"),
        key_files:       [ENV.fetch("TM_SSH_KEY_FILE", "/tmp/id_test")],
        verify_host_key: :never)
    end

    let(:ping_command) { "echo pong" }

    include_examples "a working Train transport", "ssh"
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # SSH – Linux container 2
  # ─────────────────────────────────────────────────────────────────────────────
  context "SSH transport to Linux target 2" do
    before { skip "TM_SSH_HOST_2 not configured" unless ENV["TM_SSH_HOST_2"] }

    let(:transport) do
      Train.create("ssh",
        host:            ENV.fetch("TM_SSH_HOST_2", "127.0.0.1"),
        port:            ENV.fetch("TM_SSH_PORT_2", "2223").to_i,
        user:            ENV.fetch("TM_SSH_USER", "root"),
        key_files:       [ENV.fetch("TM_SSH_KEY_FILE", "/tmp/id_test")],
        verify_host_key: :never)
    end

    let(:ping_command) { "echo pong" }

    include_examples "a working Train transport", "ssh"
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # WinRM – Windows target
  # TODO: WinRM transport support is not yet complete. Uncomment this context
  #       once the WinRM transport implementation is finished.
  # ─────────────────────────────────────────────────────────────────────────────
  # context "WinRM transport to Windows target" do
  #   before { skip "TM_WINRM_HOST not configured" unless ENV["TM_WINRM_HOST"] }
  #
  #   let(:transport) do
  #     Train.create("winrm",
  #       host:         ENV.fetch("TM_WINRM_HOST"),
  #       port:         ENV.fetch("TM_WINRM_PORT", "5985").to_i,
  #       user:         ENV.fetch("TM_WINRM_USER"),
  #       password:     ENV.fetch("TM_WINRM_PASSWORD"),
  #       ssl:          false,
  #       self_signed:  true)
  #   end
  #
  #   let(:ping_command) { "Write-Host pong" }
  #
  #   include_examples "a working Train transport", "winrm"
  # end
end
