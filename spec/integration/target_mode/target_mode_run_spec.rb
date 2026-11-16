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
# Integration tests for target-mode cookbook convergence via chef-client --target.
#
# Each example:
#   1. Writes a temporary credentials file and minimal client.rb config.
#   2. Runs `chef-client --target` against a live SSH or WinRM target.
#   3. Reconnects via Train to verify the expected remote artefacts exist,
#      providing meaningful failure output if convergence had no effect.
#
# Environment variables consumed (same guard as transport_spec.rb):
#   TM_INTEGRATION_ENABLED  – must be "true"
#
#   SSH targets:
#     TM_SSH_HOST_1 / TM_SSH_PORT_1 / TM_SSH_CREDS_1  – first  SSH target
#     TM_SSH_HOST_2 / TM_SSH_PORT_2 / TM_SSH_CREDS_2  – second SSH target
#     TM_SSH_USER / TM_SSH_KEY_FILE                    – shared auth settings
#
#   WinRM target:
#     TM_WINRM_HOST / TM_WINRM_PORT / TM_WINRM_CREDS  – WinRM target
#     TM_WINRM_USER / TM_WINRM_PASSWORD                – WinRM credentials

require "spec_helper"
require "support/shared/integration/integration_helper"
require "chef/mixin/shell_out"
require "train"
require "tmpdir"
require "fileutils"
require "chef-utils/dist"

INTEGRATION_ENABLED = ENV["TM_INTEGRATION_ENABLED"] == "true" unless defined?(INTEGRATION_ENABLED)

RSpec.describe "Target Mode Cookbook Convergence", :integration do

  include IntegrationSupport
  include Chef::Mixin::ShellOut

  # Root of the git checkout – used to resolve the test cookbook path and the
  # bundler executable so we always run the in-tree chef-client.
  let(:repo_root)       { File.expand_path("../../..", __dir__) }
  let(:cookbooks_path)  { File.join(repo_root, "spec/integration/target_mode/cookbooks") }
  let(:chef_client_bin) { "bundle exec #{ChefUtils::Dist::Infra::CLIENT}" }

  before do
    skip "Set TM_INTEGRATION_ENABLED=true to run target-mode integration tests" unless INTEGRATION_ENABLED
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Helpers
  # ─────────────────────────────────────────────────────────────────────────────

  # Write a minimal client.rb into +dir+ so chef-client has a home without
  # requiring a Chef Server.  Backslashes in Windows paths are converted to
  # forward slashes so they survive embedding in a Ruby string literal.
  def write_client_rb(dir)
    safe = ->(p) { p.tr("\\", "/") }
    File.write(File.join(dir, "client.rb"), <<~RB)
      local_mode true
      node_path      "#{safe.call(File.join(dir, "nodes"))}"
      cache_path     "#{safe.call(File.join(dir, "cache"))}"
      cookbook_path  ["#{safe.call(cookbooks_path)}"]
    RB
    FileUtils.mkdir_p(File.join(dir, "nodes"))
    FileUtils.mkdir_p(File.join(dir, "cache"))
  end

  # Run chef-client in target mode against +target_host+ using the credentials
  # file at +creds_file+.  Returns the ShellOut result.
  def run_target_mode(target_host:, creds_file:, recipe:, config_dir:)
    cmd = [
      chef_client_bin,
      "--no-fork",
      "--always-dump-stacktrace",
      "--target", target_host,
      "--config", File.join(config_dir, "client.rb"),
      "--runlist", "recipe[target_mode_test::#{recipe}]" # rubocop:disable Style/TrailingCommaInArrayLiteral
    ].join(" ")

    shell_out!(
      cmd,
      cwd:     repo_root,
      timeout: 300,
      env:     { "CHEF_CREDENTIALS_FILE" => creds_file }
    )
  end

  # Open a Train SSH connection and check that +remote_path+ contains +expected+.
  def assert_remote_file_ssh(remote_path, expected:, host:, port:, user:, key_file:)
    transport = Train.create("ssh",
      host:            host,
      port:            port.to_i,
      user:            user,
      key_files:       [key_file],
      verify_host_key: :never)
    conn   = transport.connection
    result = conn.run_command("cat #{remote_path}")
    conn.close
    expect(result.exit_status).to eq(0),
      "Remote file '#{remote_path}' could not be read (exit #{result.exit_status})"
    expect(result.stdout).to include(expected),
      "Remote file '#{remote_path}' did not contain '#{expected}'"
  end

  # TODO: WinRM transport support is not yet complete. Uncomment once finished.
  # def assert_remote_file_winrm(remote_path, expected:, host:, port:, user:, password:)
  #   transport = Train.create("winrm",
  #     host:        host,
  #     port:        port.to_i,
  #     user:        user,
  #     password:    password,
  #     ssl:         false,
  #     self_signed: true)
  #   conn   = transport.connection
  #   result = conn.run_command("Get-Content '#{remote_path}'")
  #   conn.close
  #   expect(result.exit_status).to eq(0),
  #     "Remote file '#{remote_path}' could not be read (exit #{result.exit_status})"
  #   expect(result.stdout).to include(expected),
  #     "Remote file '#{remote_path}' did not contain '#{expected}'"
  # end

  # ─────────────────────────────────────────────────────────────────────────────
  # SSH – Linux target 1
  # ─────────────────────────────────────────────────────────────────────────────
  context "SSH transport → Linux target 1" do
    before { skip "TM_SSH_HOST_1 / TM_SSH_CREDS_1 not configured" unless ENV["TM_SSH_HOST_1"] && ENV["TM_SSH_CREDS_1"] }

    let(:ssh_host)  { ENV.fetch("TM_SSH_HOST_1") }
    let(:ssh_port)  { ENV.fetch("TM_SSH_PORT_1", "2222") }
    let(:ssh_user)  { ENV.fetch("TM_SSH_USER", "root") }
    let(:ssh_key)   { ENV.fetch("TM_SSH_KEY_FILE", "/tmp/id_test") }
    let(:creds_1)   { ENV.fetch("TM_SSH_CREDS_1") }

    let(:tmp_dir) { Dir.mktmpdir("chef-tm-ssh1") }
    before { write_client_rb(tmp_dir) }
    after  { FileUtils.remove_entry(tmp_dir, true) }

    it "converges target_mode_test::linux without errors" do
      result = run_target_mode(
        target_host: ssh_host,
        creds_file:  creds_1,
        recipe:      "linux",
        config_dir:  tmp_dir
      )
      expect(result.exitstatus).to eq(0)
    end

    it "creates the expected file on the remote Linux target" do
      run_target_mode(target_host: ssh_host, creds_file: creds_1, recipe: "linux", config_dir: tmp_dir)
      assert_remote_file_ssh(
        "/tmp/chef_tm_test/hello.txt",
        expected: "Hello from Chef target mode!",
        host:     ssh_host,
        port:     ssh_port,
        user:     ssh_user,
        key_file: ssh_key
      )
    end

    it "is idempotent on a second converge" do
      run_target_mode(target_host: ssh_host, creds_file: creds_1, recipe: "linux", config_dir: tmp_dir)
      second = run_target_mode(target_host: ssh_host, creds_file: creds_1, recipe: "linux", config_dir: tmp_dir)
      expect(second.stdout).to match(/0 resources updated/i).or match(%r{Infra Phase complete, 0/}i)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # SSH – Linux target 2
  # ─────────────────────────────────────────────────────────────────────────────
  context "SSH transport → Linux target 2" do
    before { skip "TM_SSH_HOST_2 / TM_SSH_CREDS_2 not configured" unless ENV["TM_SSH_HOST_2"] && ENV["TM_SSH_CREDS_2"] }

    let(:ssh_host)  { ENV.fetch("TM_SSH_HOST_2") }
    let(:ssh_port)  { ENV.fetch("TM_SSH_PORT_2", "2223") }
    let(:ssh_user)  { ENV.fetch("TM_SSH_USER", "root") }
    let(:ssh_key)   { ENV.fetch("TM_SSH_KEY_FILE", "/tmp/id_test") }
    let(:creds_2)   { ENV.fetch("TM_SSH_CREDS_2") }

    let(:tmp_dir) { Dir.mktmpdir("chef-tm-ssh2") }
    before { write_client_rb(tmp_dir) }
    after  { FileUtils.remove_entry(tmp_dir, true) }

    it "converges target_mode_test::linux without errors" do
      result = run_target_mode(
        target_host: ssh_host,
        creds_file:  creds_2,
        recipe:      "linux",
        config_dir:  tmp_dir
      )
      expect(result.exitstatus).to eq(0)
    end

    it "creates the expected file on the remote Linux target" do
      run_target_mode(target_host: ssh_host, creds_file: creds_2, recipe: "linux", config_dir: tmp_dir)
      assert_remote_file_ssh(
        "/tmp/chef_tm_test/hello.txt",
        expected: "Hello from Chef target mode!",
        host:     ssh_host,
        port:     ssh_port,
        user:     ssh_user,
        key_file: ssh_key
      )
    end

    it "is idempotent on a second converge" do
      run_target_mode(target_host: ssh_host, creds_file: creds_2, recipe: "linux", config_dir: tmp_dir)
      second = run_target_mode(target_host: ssh_host, creds_file: creds_2, recipe: "linux", config_dir: tmp_dir)
      expect(second.stdout).to match(/0 resources updated/i).or match(%r{Infra Phase complete, 0/}i)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # WinRM – Windows target
  # TODO: WinRM transport support is not yet complete. Uncomment this context
  #       once the WinRM transport implementation is finished.
  # ─────────────────────────────────────────────────────────────────────────────
  # context "WinRM transport → Windows target" do
  #   before { skip "TM_WINRM_HOST / TM_WINRM_CREDS not configured" unless ENV["TM_WINRM_HOST"] && ENV["TM_WINRM_CREDS"] }
  #
  #   let(:winrm_host)     { ENV.fetch("TM_WINRM_HOST") }
  #   let(:winrm_port)     { ENV.fetch("TM_WINRM_PORT", "5985") }
  #   let(:winrm_user)     { ENV.fetch("TM_WINRM_USER") }
  #   let(:winrm_password) { ENV.fetch("TM_WINRM_PASSWORD") }
  #   let(:creds_winrm)    { ENV.fetch("TM_WINRM_CREDS") }
  #
  #   let(:tmp_dir) { Dir.mktmpdir("chef-tm-winrm") }
  #   before { write_client_rb(tmp_dir) }
  #   after  { FileUtils.remove_entry(tmp_dir, true) }
  #
  #   it "converges target_mode_test::windows without errors" do
  #     result = run_target_mode(
  #       target_host: winrm_host,
  #       creds_file:  creds_winrm,
  #       recipe:      "windows",
  #       config_dir:  tmp_dir
  #     )
  #     expect(result.exitstatus).to eq(0)
  #   end
  #
  #   it "creates the expected file on the remote Windows target" do
  #     run_target_mode(target_host: winrm_host, creds_file: creds_winrm, recipe: "windows", config_dir: tmp_dir)
  #     assert_remote_file_winrm(
  #       'C:\chef_tm_test\hello.txt',
  #       expected: "Hello from Chef target mode!",
  #       host:     winrm_host,
  #       port:     winrm_port,
  #       user:     winrm_user,
  #       password: winrm_password
  #     )
  #   end
  #
  #   it "is idempotent on a second converge" do
  #     run_target_mode(target_host: winrm_host, creds_file: creds_winrm, recipe: "windows", config_dir: tmp_dir)
  #     second = run_target_mode(target_host: winrm_host, creds_file: creds_winrm, recipe: "windows", config_dir: tmp_dir)
  #     expect(second.stdout).to match(/0 resources updated/i).or match(/Chef Client finished/i)
  #   end
  # end
end
