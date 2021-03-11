#
# Copyright:: Copyright (c) Chef Software Inc.
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

require "knife_spec_helper"
require "ostruct"
require "chef/knife/bootstrap/train_connector"

describe Chef::Knife::Bootstrap::TrainConnector do
  let(:protocol) { "mock" }
  let(:family) { "unknown" }
  let(:release) { "unknown" } # version
  let(:name) { "unknown" }
  let(:arch) { "x86_64" }
  let(:connection_opts) { {} } # connection opts
  let(:host_url) { "mock://user1@example.com" }
  let(:mock_connection) { true }

  subject do
    # Example groups can still override by setting explicitly it in 'connection_opts'
    tc = Chef::Knife::Bootstrap::TrainConnector.new(host_url, protocol, connection_opts)
    tc
  end

  before(:each) do
    if mock_connection
      subject.connect!
      subject.connection.mock_os(
        family: family,
        name: name,
        release: release,
        arch: arch
      )
    end
  end

  describe "platform helpers" do
    context "on linux" do
      let(:family) { "debian" }
      let(:name) { "ubuntu" }
      it "reports that it is linux and unix, because that is how train classifies it" do
        expect(subject.unix?).to eq true
        expect(subject.linux?).to eq true
        expect(subject.windows?).to eq false
      end
    end
    context "on unix" do
      let(:family) { "os" }
      let(:name) { "mac_os_x" }
      it "reports only a unix OS" do
        expect(subject.unix?).to eq true
        expect(subject.linux?).to eq false
        expect(subject.windows?).to eq false
      end
    end
    context "on windows" do
      let(:family) { "windows" }
      let(:name) { "windows" }
      it "reports only a windows OS" do
        expect(subject.unix?).to eq false
        expect(subject.linux?).to eq false
        expect(subject.windows?).to eq true
      end
    end
  end

  describe "#connect!" do
    it "establishes the connection to the remote host by waiting for it" do
      expect(subject.connection).to receive(:wait_until_ready)
      subject.connect!
    end
  end

  describe "#initialize" do
    let(:mock_connection) { false }

    context "when provided target is a proper URL" do
      let(:protocol) { "ssh" }
      let(:host_url) { "mock://user1@localhost:2200" }
      it "correctly configures the instance from the URL" do
        expect(subject.config[:backend]).to eq "mock"
        expect(subject.config[:port]).to eq 2200
        expect(subject.config[:host]).to eq "localhost"
        expect(subject.config[:user]).to eq "user1"
      end

      context "and conflicting options are given" do
        let(:connection_opts) { { user: "user2", host: "example.com", port: 15 } }
        it "resolves them from the URI" do
          expect(subject.config[:backend]).to eq "mock"
          expect(subject.config[:port]).to eq 2200
          expect(subject.config[:host]).to eq "localhost"
          expect(subject.config[:user]).to eq "user1"
        end
      end
    end

    context "when provided target is just a hostname" do
      let(:host_url) { "localhost" }
      let(:protocol) { "mock" }
      it "correctly sets backend protocol from the default" do
        expect(subject.config[:backend]).to eq "mock"
      end

      context "and options have been provided that are supported by the transport" do
        let(:protocol) { "ssh" }
        let(:connection_opts) { { port: 15, user: "user2" } }

        it "sets hostname and transport from arguments and provided fields from options" do
          expect(subject.config[:backend]).to eq "ssh"
          expect(subject.config[:host]).to eq "localhost"
          expect(subject.config[:user]).to eq "user2"
          expect(subject.config[:port]).to eq 15
        end

      end

    end

    context "when provided target is just a an IP address" do
      let(:host_url) { "127.0.0.1" }
      let(:protocol) { "mock" }
      it "correctly sets backend protocol from the default" do
        expect(subject.config[:backend]).to eq "mock"
      end
    end
  end

  describe "#temp_dir" do
    context "under windows" do
      let(:family) { "windows" }
      let(:name) { "windows" }

      it "uses the windows command to create the temp dir" do
        expected_command = Chef::Knife::Bootstrap::TrainConnector::MKTEMP_WIN_COMMAND
        expect(subject).to receive(:run_command!).with(expected_command)
          .and_return double("result", stdout: "C:/a/path")
        expect(subject.temp_dir).to eq "C:/a/path"
      end

    end
    context "under linux and unix-like" do
      let(:family) { "debian" }
      let(:name) { "ubuntu" }
      let(:random) { "wScHX6" }
      let(:dir) { "/tmp/chef_#{random}" }

      before do
        allow(SecureRandom).to receive(:alphanumeric).with(6).and_return(random)
      end

      context "uses the *nix command to create the temp dir and sets ownership to logged-in" do
        it "with sudo privilege" do
          subject.config[:sudo] = true
          expected_command1 = "mkdir -p '#{dir}'"
          expected_command2 = "chown user1 '#{dir}'"
          expect(subject).to receive(:run_command!).with(expected_command1)
            .and_return double("result", stdout: "\r\n")
          expect(subject).to receive(:run_command!).with(expected_command2)
            .and_return double("result", stdout: "\r\n")
          expect(subject.temp_dir).to eq(dir)
        end

        it "without sudo privilege" do
          expected_command = "mkdir -p '#{dir}'"
          expect(subject).to receive(:run_command!).with(expected_command)
            .and_return double("result", stdout: "\r\n")
          expect(subject.temp_dir).to eq(dir)
        end
      end

      context "with noise in stderr" do
        it "uses the *nix command to create the temp dir" do
          expected_command = "mkdir -p '#{dir}'"
          expect(subject).to receive(:run_command!).with(expected_command)
            .and_return double("result", stdout: "sudo: unable to resolve host hostname.localhost\r\n" + "#{dir}\r\n")
          expect(subject.temp_dir).to eq(dir)
        end
      end
    end
  end
  context "#upload_file_content!" do
    it "creates a local file with expected content and uploads it" do
      expect(subject).to receive(:upload_file!) do |local_path, remote_path|
        expect(File.read(local_path)).to eq "test data"
        expect(remote_path).to eq "/target/path"
      end
      expect_any_instance_of(Tempfile).to receive(:binmode)
      subject.upload_file_content!("test data", "/target/path")
    end
  end

  context "del_file" do
    context "on windows" do
      let(:family) { "windows" }
      let(:name) { "windows" }
      it "deletes the file with a windows command" do
        expect(subject).to receive(:run_command!) do |cmd, &_handler|
          expect(cmd).to match(/Test-Path "deleteme\.txt".*/)
        end
        subject.del_file!("deleteme.txt")
      end
    end
    context "on unix-like" do
      let(:family) { "debian" }
      let(:name) { "ubuntu" }
      it "deletes the file with a windows command" do
        expect(subject).to receive(:run_command!) do |cmd, &_handler|
          expect(cmd).to match(/rm -f "deleteme\.txt".*/)
        end
        subject.del_file!("deleteme.txt")
      end
    end
  end

  context "#run_command!" do
    it "raises a RemoteExecutionFailed when the remote execution failed" do
      command_result = double("results", stdout: "", stderr: "failed", exit_status: 1)
      expect(subject).to receive(:run_command).and_return command_result

      expect { subject.run_command!("test") }.to raise_error do |e|
        expect(e.hostname).to eq subject.hostname
        expect(e.class).to eq Chef::Knife::Bootstrap::RemoteExecutionFailed
        expect(e.stderr).to eq "failed"
        expect(e.stdout).to eq ""
        expect(e.exit_status).to eq 1
      end
    end
  end

end
