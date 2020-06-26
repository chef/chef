#
# Author:: Bryan McLellan <btm@chef.io>
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

require "spec_helper"
require_relative "../../../lib/chef/knife/winrm"
require_relative "../../support/dummy_winrm_connection"

describe Chef::Knife::Winrm do
  before do
    Chef::Config.reset
  end

  describe "#resolve_target_nodes" do
    before do
      @knife = Chef::Knife::Winrm.new
      @knife.config[:attribute] = "fqdn"
      @node_foo = Chef::Node.new
      @node_foo.automatic_attrs[:fqdn] = "foo.example.org"
      @node_foo.automatic_attrs[:ipaddress] = "10.0.0.1"
      @node_bar = Chef::Node.new
      @node_bar.automatic_attrs[:fqdn] = "bar.example.org"
      @node_bar.automatic_attrs[:ipaddress] = "10.0.0.2"
      @node_bar.automatic_attrs[:ec2][:public_hostname] = "somewhere.com"
      @query = double("Chef::Search::Query")
    end

    context "when there are some hosts found but they do not have an attribute to connect with" do
      before do
        @knife.config[:manual] = false
        @knife.config[:winrm_password] = "P@ssw0rd!"
        allow(@query).to receive(:search).and_return([[@node_foo, @node_bar]])
        @node_foo.automatic_attrs[:fqdn] = nil
        @node_bar.automatic_attrs[:fqdn] = nil
        allow(Chef::Search::Query).to receive(:new).and_return(@query)
      end

      it "raises a specific error (KNIFE-222)" do
        expect(@knife.ui).to receive(:fatal).with(/does not have the required attribute/)
        expect(@knife).to receive(:exit).with(10)
        @knife.configure_chef
        @knife.resolve_target_nodes
      end
    end

    context "when there are nested attributes" do
      before do
        @knife.config[:manual] = false
        @knife.config[:winrm_password] = "P@ssw0rd!"
        allow(@query).to receive(:search).and_return([[@node_foo, @node_bar]])
        allow(Chef::Search::Query).to receive(:new).and_return(@query)
      end

      it "uses the nested attributes (KNIFE-276)" do
        @knife.config[:attribute] = "ec2.public_hostname"
        @knife.configure_chef
        @knife.resolve_target_nodes
      end
    end
  end

  describe "#configure_session" do
    let(:winrm_user) { "testuser" }
    let(:transport) { "plaintext" }
    let(:password) { "testpassword" }
    let(:protocol) { "basic" }
    let(:knife_args) do
      [
        "-m", "localhost",
        "-x", winrm_user,
        "-P", password,
        "-w", transport,
        "--winrm-authentication-protocol", protocol,
        "echo helloworld"
      ]
    end
    let(:winrm_session) { double("winrm_session") }
    let(:winrm_connection) { Dummy::Connection.new }

    subject { Chef::Knife::Winrm.new(knife_args) }

    context "when configuring the WinRM user name" do
      context "when basic auth is used" do
        let(:protocol) { "basic" }

        it "passes user name as given in options" do
          expect(Chef::Knife::WinrmSession).to receive(:new) do |opts|
            expect(opts[:user]).to eq(winrm_user)
          end.and_return(winrm_session)
          subject.configure_session
        end
      end

      context "when negotiate auth is used" do
        let(:protocol) { "negotiate" }

        context "when user is prefixed with realm" do
          let(:winrm_user) { "my_realm\\myself" }

          it "passes user name as given in options" do
            expect(Chef::Knife::WinrmSession).to receive(:new) do |opts|
              expect(opts[:user]).to eq(winrm_user)
            end.and_return(winrm_session)
            subject.configure_session
          end
        end

        context "when user realm is included via email format" do
          let(:winrm_user) { "myself@my_realm.com" }

          it "passes user name as given in options" do
            expect(Chef::Knife::WinrmSession).to receive(:new) do |opts|
              expect(opts[:user]).to eq(winrm_user)
            end.and_return(winrm_session)
            subject.configure_session
          end
        end

        context "when a local user is given" do
          it "prefixes user with the dot (local) realm" do
            expect(Chef::Knife::WinrmSession).to receive(:new) do |opts|
              expect(opts[:user]).to eq(".\\#{winrm_user}")
            end.and_return(winrm_session)
            subject.configure_session
          end
        end
      end
    end

    context "when configuring the WinRM password" do
      it "passes password as given in options" do
        expect(Chef::Knife::WinrmSession).to receive(:new) do |opts|
          expect(opts[:password]).to eq(password)
        end.and_return(winrm_session)
        subject.configure_session
      end

      context "when no password is given in the options" do
        let(:knife_args) do
          [
            "-m", "localhost",
            "-x", winrm_user,
            "-w", transport,
            "--winrm-authentication-protocol", protocol,
            "echo helloworld"
          ]
        end
        let(:prompted_password) { "prompted_password" }

        before do
          allow(subject.ui).to receive(:ask).and_return(prompted_password)
        end

        it "passes password prompted" do
          expect(Chef::Knife::WinrmSession).to receive(:new) do |opts|
            expect(opts[:password]).to eq(prompted_password)
          end.and_return(winrm_session)
          subject.configure_session
        end
      end
    end

    context "when configuring the WinRM transport" do
      context "kerberos option is set" do
        let(:winrm_command_http) {
          Chef::Knife::Winrm.new([
          "-m", "localhost",
          "-x", "testuser",
          "-P", "testpassword",
          "--winrm-authentication-protocol", "basic",
          "--kerberos-realm", "realm",
          "echo helloworld"
        ])
        }

        it "sets the transport to kerberos" do
          expect(WinRM::Connection).to receive(:new).with(hash_including(transport: :kerberos)).and_return(winrm_connection)
          winrm_command_http.configure_chef
          winrm_command_http.configure_session
        end
      end

      context "kerberos option is set but nil" do
        let(:winrm_command_http) {
          Chef::Knife::Winrm.new([
          "-m", "localhost",
          "-x", "testuser",
          "-P", "testpassword",
          "--winrm-authentication-protocol", "basic",
          "echo helloworld"
        ])
        }

        it "sets the transport to plaintext" do
          winrm_command_http.config[:kerberos_realm] = nil
          expect(WinRM::Connection).to receive(:new).with(hash_including(transport: :plaintext)).and_return(winrm_connection)
          winrm_command_http.configure_chef
          winrm_command_http.configure_session
        end
      end

      context "on windows workstations" do
        let(:protocol) { "negotiate" }

        before do
          allow(Chef::Platform).to receive(:windows?).and_return(true)
        end

        it "defaults to negotiate when on a Windows host" do
          expect(Chef::Knife::WinrmSession).to receive(:new) do |opts|
            expect(opts[:transport]).to eq(:negotiate)
          end.and_return(winrm_session)
          subject.configure_session
        end
      end

      context "on non-windows workstations" do
        before do
          allow(Chef::Platform).to receive(:windows?).and_return(false)
        end

        let(:winrm_command_http) { Chef::Knife::Winrm.new(["-m", "localhost", "-x", "testuser", "-P", "testpassword", "-w", "plaintext", "--winrm-authentication-protocol", "basic", "echo helloworld"]) }

        it "defaults to the http uri scheme" do
          expect(Chef::Knife::WinrmSession).to receive(:new).with(hash_including(transport: :plaintext)).and_call_original
          expect(WinRM::Connection).to receive(:new).with(hash_including(endpoint: "http://localhost:5985/wsman")).and_return(winrm_connection)
          winrm_command_http.configure_chef
          winrm_command_http.configure_session
        end

        it "sets the operation timeout and verifes default" do
          expect(Chef::Knife::WinrmSession).to receive(:new).with(hash_including(operation_timeout: 1800)).and_call_original
          expect(WinRM::Connection).to receive(:new).with(hash_including(operation_timeout: 1800)).and_return(winrm_connection)
          winrm_command_http.configure_chef
          winrm_command_http.configure_session
        end

        it "sets the user specified winrm port" do
          winrm_command_http.config[:knife] = { winrm_port: "5988" }
          expect(Chef::Knife::WinrmSession).to receive(:new).with(hash_including(transport: :plaintext)).and_call_original
          expect(WinRM::Connection).to receive(:new).with(hash_including(transport: :plaintext)).and_return(winrm_connection)
          winrm_command_http.configure_chef
          winrm_command_http.configure_session
        end

        let(:winrm_command_timeout) { Chef::Knife::Winrm.new(["-m", "localhost", "-x", "testuser", "-P", "testpassword", "--winrm-authentication-protocol", "basic", "--session-timeout", "10", "echo helloworld"]) }

        it "sets operation timeout and verify 10 Minute timeout" do
          expect(Chef::Knife::WinrmSession).to receive(:new).with(hash_including(operation_timeout: 600)).and_call_original
          expect(WinRM::Connection).to receive(:new).with(hash_including(operation_timeout: 600)).and_return(winrm_connection)
          winrm_command_timeout.configure_chef
          winrm_command_timeout.configure_session
        end

        let(:winrm_command_https) { Chef::Knife::Winrm.new(["-m", "localhost", "-x", "testuser", "-P", "testpassword", "--winrm-transport", "ssl", "echo helloworld"]) }

        it "uses the https uri scheme if the ssl transport is specified" do
          winrm_command_http.config[:winrm_transport] = "ssl"
          expect(Chef::Knife::WinrmSession).to receive(:new).with(hash_including(transport: :ssl)).and_call_original
          expect(WinRM::Connection).to receive(:new).with(hash_including(endpoint: "https://localhost:5986/wsman")).and_return(winrm_connection)
          winrm_command_https.configure_chef
          winrm_command_https.configure_session
        end

        it "uses the winrm port '5986' by default for ssl transport" do
          winrm_command_http.config[:winrm_transport] = "ssl"
          expect(Chef::Knife::WinrmSession).to receive(:new).with(hash_including(transport: :ssl)).and_call_original
          expect(WinRM::Connection).to receive(:new).with(hash_including(endpoint: "https://localhost:5986/wsman")).and_return(winrm_connection)
          winrm_command_https.configure_chef
          winrm_command_https.configure_session
        end

        it "defaults to validating the server when the ssl transport is used" do
          expect(Chef::Knife::WinrmSession).to receive(:new).with(hash_including(transport: :ssl)).and_call_original
          expect(WinRM::Connection).to receive(:new).with(hash_including(no_ssl_peer_verification: false)).and_return(winrm_connection)
          winrm_command_https.configure_chef
          winrm_command_https.configure_session
        end

        let(:winrm_command_verify_peer) { Chef::Knife::Winrm.new(["-m", "localhost", "-x", "testuser", "-P", "testpassword", "--winrm-transport", "ssl", "--winrm-ssl-verify-mode", "verify_peer", "echo helloworld"]) }

        it "validates the server when the ssl transport is used and the :winrm_ssl_verify_mode option is not configured to :verify_none" do
          expect(Chef::Knife::WinrmSession).to receive(:new).with(hash_including(transport: :ssl)).and_call_original
          expect(WinRM::Connection).to receive(:new).with(hash_including(no_ssl_peer_verification: false)).and_return(winrm_connection)
          winrm_command_verify_peer.configure_chef
          winrm_command_verify_peer.configure_session
        end

        context "when setting verify_none" do
          let(:transport) { "ssl" }

          before { knife_args << "--winrm-ssl-verify-mode" << "verify_none" }

          it "does not validate the server when the ssl transport is used and the :winrm_ssl_verify_mode option is set to :verify_none" do
            expect(Chef::Knife::WinrmSession).to receive(:new).with(hash_including(transport: :ssl)).and_call_original
            expect(WinRM::Connection).to receive(:new).with(hash_including(no_ssl_peer_verification: true)).and_return(winrm_connection)
            subject.configure_chef
            subject.configure_session
          end

          it "prints warning output when the :winrm_ssl_verify_mode set to :verify_none to disable server validation" do
            expect(Chef::Knife::WinrmSession).to receive(:new).with(hash_including(transport: :ssl)).and_call_original
            expect(WinRM::Connection).to receive(:new).with(hash_including(no_ssl_peer_verification: true)).and_return(winrm_connection)
            expect(subject).to receive(:warn_no_ssl_peer_verification)

            subject.configure_chef
            subject.configure_session
          end

          context "when transport is plaintext" do
            let(:transport) { "plaintext" }

            it "does not print warning re ssl server validation" do
              expect(Chef::Knife::WinrmSession).to receive(:new).with(hash_including(transport: :plaintext)).and_call_original
              expect(WinRM::Connection).to receive(:new).and_return(winrm_connection)
              expect(subject).to_not receive(:warn_no_ssl_peer_verification)

              subject.configure_chef
              subject.configure_session
            end
          end
        end

        let(:winrm_command_ca_trust) { Chef::Knife::Winrm.new(["-m", "localhost", "-x", "testuser", "-P", "testpassword", "--winrm-transport", "ssl", "--ca-trust-file", "~/catrustroot", "--winrm-ssl-verify-mode", "verify_none", "echo helloworld"]) }

        it "validates the server when the ssl transport is used and the :ca_trust_file option is specified even if the :winrm_ssl_verify_mode option is set to :verify_none" do
          expect(Chef::Knife::WinrmSession).to receive(:new).with(hash_including(transport: :ssl)).and_call_original
          expect(WinRM::Connection).to receive(:new).with(hash_including(no_ssl_peer_verification: false)).and_return(winrm_connection)
          winrm_command_ca_trust.configure_chef
          winrm_command_ca_trust.configure_session
        end
      end
    end
  end

  describe "#run" do
    let(:session_opts) do
      {
        user: ".\\testuser",
        password: "testpassword",
        port: "5985",
        transport: :plaintext,
        host: "localhost",
      }
    end
    let(:session) { Chef::Knife::WinrmSession.new(session_opts) }

    before(:each) do
      allow(Chef::Knife::WinrmSession).to receive(:new).and_return(session)
      @winrm = Chef::Knife::Winrm.new(["-m", "localhost", "-x", "testuser", "-P", "testpassword", "--winrm-authentication-protocol", "basic", "echo helloworld"])
      @winrm.config[:winrm_transport] = "plaintext"
    end

    it "returns with 0 if the command succeeds" do
      allow(@winrm).to receive(:relay_winrm_command).and_return(0)
      return_code = @winrm.run
      expect(return_code).to be_zero
    end

    it "exits with exact exit status if the command fails and returns config is set to 0" do
      command_status = 510

      @winrm.config[:returns] = "0"

      allow(@winrm).to receive(:relay_winrm_command)
      allow(@winrm.ui).to receive(:error)
      allow(session).to receive(:exit_code).and_return(command_status)
      expect { @winrm.run_with_pretty_exceptions }.to raise_error(SystemExit) { |e| expect(e.status).to eq(command_status) }
    end

    it "exits with non-zero status if the command fails and returns config is set to 0" do
      command_status = 1
      @winrm.config[:returns] = "0,53"
      allow(@winrm).to receive(:relay_winrm_command).and_return(command_status)
      allow(@winrm.ui).to receive(:error)
      allow(session).to receive(:exit_code).and_return(command_status)
      expect { @winrm.run_with_pretty_exceptions }.to raise_error(SystemExit) { |e| expect(e.status).to eq(command_status) }
    end

    it "exits with a zero status if the command returns an expected non-zero status" do
      command_status = 53
      @winrm.config[:returns] = "0,53"
      allow(@winrm).to receive(:relay_winrm_command).and_return(command_status)
      allow(session).to receive(:exit_codes).and_return({ "thishost" => command_status })
      exit_code = @winrm.run
      expect(exit_code).to be_zero
    end

    it "exits with a zero status if the command returns an expected non-zero status" do
      command_status = 53
      @winrm.config[:returns] = "0,53"
      allow(@winrm).to receive(:relay_winrm_command).and_return(command_status)
      allow(session).to receive(:exit_codes).and_return({ "thishost" => command_status })
      exit_code = @winrm.run
      expect(exit_code).to be_zero
    end

    it "exits with 100 and no hint if command execution raises an exception other than 401" do
      allow(@winrm).to receive(:relay_winrm_command).and_raise(WinRM::WinRMHTTPTransportError.new("", "500"))
      allow(@winrm.ui).to receive(:error)
      expect(@winrm.ui).to_not receive(:info)
      expect { @winrm.run_with_pretty_exceptions }.to raise_error(SystemExit) { |e| expect(e.status).to eq(100) }
    end

    it "exits with 100 if command execution raises a 401" do
      allow(@winrm).to receive(:relay_winrm_command).and_raise(WinRM::WinRMHTTPTransportError.new("", "401"))
      allow(@winrm.ui).to receive(:info)
      allow(@winrm.ui).to receive(:error)
      expect { @winrm.run_with_pretty_exceptions }.to raise_error(SystemExit) { |e| expect(e.status).to eq(100) }
    end

    it "prints a hint on failure for negotiate authentication" do
      @winrm.config[:winrm_authentication_protocol] = "negotiate"
      @winrm.config[:winrm_transport] = "plaintext"
      allow(Chef::Platform).to receive(:windows?).and_return(true)
      allow(session).to receive(:relay_command).and_raise(WinRM::WinRMAuthorizationError.new)
      allow(@winrm.ui).to receive(:error)
      allow(@winrm.ui).to receive(:info)
      expect(@winrm.ui).to receive(:info).with(Chef::Knife::Winrm::FAILED_NOT_BASIC_HINT)
      expect { @winrm.run_with_pretty_exceptions }.to raise_error(SystemExit)
    end

    it "prints a hint on failure for basic authentication" do
      @winrm.config[:winrm_authentication_protocol] = "basic"
      @winrm.config[:winrm_transport] = "plaintext"
      allow(session).to receive(:relay_command).and_raise(WinRM::WinRMHTTPTransportError.new("", "401"))
      allow(@winrm.ui).to receive(:error)
      allow(@winrm.ui).to receive(:info)
      expect(@winrm.ui).to receive(:info).with(Chef::Knife::Winrm::FAILED_BASIC_HINT)
      expect { @winrm.run_with_pretty_exceptions }.to raise_error(SystemExit)
    end

    context "when winrm_authentication_protocol specified" do
      before do
        @winrm.config[:winrm_transport] = "plaintext"
        allow(@winrm).to receive(:relay_winrm_command).and_return(0)
      end

      it "sets negotiate transport on windows for 'negotiate' authentication" do
        @winrm.config[:winrm_authentication_protocol] = "negotiate"
        allow(Chef::Platform).to receive(:windows?).and_return(true)
        allow(Chef::Knife::WinrmSession).to receive(:new) do |opts|
          expect(opts[:disable_sspi]).to be(false)
          expect(opts[:transport]).to be(:negotiate)
        end.and_return(session)
        @winrm.run
      end

      it "sets negotiate transport on unix for 'negotiate' authentication" do
        @winrm.config[:winrm_authentication_protocol] = "negotiate"
        allow(Chef::Platform).to receive(:windows?).and_return(false)
        allow(Chef::Knife::WinrmSession).to receive(:new) do |opts|
          expect(opts[:disable_sspi]).to be(false)
          expect(opts[:transport]).to be(:negotiate)
        end.and_return(session)
        @winrm.run
      end

      it "disables sspi and skips the winrm monkey patch for 'ssl' transport and 'basic' authentication" do
        @winrm.config[:winrm_authentication_protocol] = "basic"
        @winrm.config[:winrm_transport] = "ssl"
        @winrm.config[:winrm_port] = "5986"
        allow(Chef::Platform).to receive(:windows?).and_return(true)
        allow(Chef::Knife::WinrmSession).to receive(:new) do |opts|
          expect(opts[:port]).to be(@winrm.config[:winrm_port])
          expect(opts[:transport]).to be(:ssl)
          expect(opts[:disable_sspi]).to be(true)
          expect(opts[:basic_auth_only]).to be(true)
        end.and_return(session)
        @winrm.run
      end

      it "raises an error if value is other than [basic, negotiate, kerberos]" do
        @winrm.config[:winrm_authentication_protocol] = "invalid"
        allow(Chef::Platform).to receive(:windows?).and_return(true)
        expect(@winrm.ui).to receive(:error)
        expect { @winrm.run }.to raise_error(SystemExit)
      end
    end
  end

  context "Impact of concurrency value when target nodes are 3" do
    let(:winrm_user) { "testuser" }
    let(:transport) { "plaintext" }
    let(:password) { "testpassword" }
    let(:protocol) { "basic" }
    let(:knife_args) do
      [
        "-m", "localhost knownhost somehost",
        "-x", winrm_user,
        "-P", password,
        "-w", transport,
        "--winrm-authentication-protocol", protocol,
        "echo helloworld"
      ]
    end
    let(:winrm_connection) { Dummy::Connection.new }

    subject { Chef::Knife::Winrm.new(knife_args) }

    context "when concurrency limit is not set" do
      it "spawns a number of connection threads equal to the number of target nodes" do
        allow(subject).to receive(:run_command_in_thread).and_return("echo helloworld")
        expect(Thread).to receive(:new).exactly(3).times.and_call_original
        subject.configure_session
        subject.relay_winrm_command(knife_args.last)
      end
    end

    context "when concurrency limit is set" do
      it "starts only the required number of threads when there are fewer targets than threads" do
        knife_args.push("-C", "4")
        allow(subject).to receive(:run_command_in_thread).and_return("echo helloworld")
        expect(Thread).to receive(:new).exactly(3).times.and_call_original
        subject.configure_session
        subject.relay_winrm_command(knife_args.last)
      end
      it "starts only the requested number of threads when there are as many targets as threads" do
        knife_args.push("-C", "3")
        allow(subject).to receive(:run_command_in_thread).and_return("echo helloworld")
        expect(Thread).to receive(:new).exactly(3).times.and_call_original
        subject.configure_session
        subject.relay_winrm_command(knife_args.last)
      end
      it "starts only the requested number of threads when there are more targets then threads" do
        knife_args.push("-C", "2")
        allow(subject).to receive(:run_command_in_thread).and_return("echo helloworld")
        expect(Thread).to receive(:new).exactly(2).times.and_call_original
        subject.configure_session
        subject.relay_winrm_command(knife_args.last)
      end
    end

    context "should call run_command_in_thread thrice when" do
      it "concurrency not set" do
        expect(subject).to receive(:run_command_in_thread).thrice
        subject.configure_session
        subject.relay_winrm_command(knife_args.last)
      end
      it "concurrency set to 4" do
        knife_args.push("-C", "4")
        expect(subject).to receive(:run_command_in_thread).thrice
        subject.configure_session
        subject.relay_winrm_command(knife_args.last)
      end
      it "concurrency set to 3" do
        knife_args.push("-C", "3")
        expect(subject).to receive(:run_command_in_thread).thrice
        subject.configure_session
        subject.relay_winrm_command(knife_args.last)
      end
      it "concurrency set to 2" do
        knife_args.push("-C", "2")
        expect(subject).to receive(:run_command_in_thread).thrice
        subject.configure_session
        subject.relay_winrm_command(knife_args.last)
      end
      it "concurrency set to 1" do
        knife_args.push("-C", "1")
        expect(subject).to receive(:run_command_in_thread).thrice
        subject.configure_session
        subject.relay_winrm_command(knife_args.last)
      end
      it "concurrency set to 0" do
        knife_args.push("-C", "0")
        expect(subject).to receive(:run_command_in_thread).thrice
        subject.configure_session
        subject.relay_winrm_command(knife_args.last)
      end
    end
  end
end
