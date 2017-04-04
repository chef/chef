#
# Author:: Steven Murawski (<smurawski@chef.io>)
# Copyright:: Copyright 2016, Chef Software, Inc.
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

require "chef"
require "spec_helper"

require "chef/application/exit_code"

describe Chef::Application::ExitCode do

  let(:exit_codes) { Chef::Application::ExitCode }

  let(:valid_rfc_exit_codes) { Chef::Application::ExitCode::VALID_RFC_062_EXIT_CODES.values }

  context "Validates the return codes from RFC 062" do

    before do
      allow(Chef::Config).to receive(:[]).with(:exit_status).and_return(:enabled)
    end

    it "validates a SUCCESS return code of 0" do
      expect(valid_rfc_exit_codes.include?(0)).to eq(true)
    end

    it "validates a GENERIC_FAILURE return code of 1" do
      expect(valid_rfc_exit_codes.include?(1)).to eq(true)
    end

    it "validates a SIGINT_RECEIVED return code of 2" do
      expect(valid_rfc_exit_codes.include?(2)).to eq(true)
    end

    it "validates a SIGTERM_RECEIVED return code of 3" do
      expect(valid_rfc_exit_codes.include?(3)).to eq(true)
    end

    it "validates a AUDIT_MODE_FAILURE return code of 42" do
      expect(valid_rfc_exit_codes.include?(42)).to eq(true)
    end

    it "validates a REBOOT_SCHEDULED return code of 35" do
      expect(valid_rfc_exit_codes.include?(35)).to eq(true)
    end

    it "validates a REBOOT_NEEDED return code of 37" do
      expect(valid_rfc_exit_codes.include?(37)).to eq(true)
    end

    it "validates a REBOOT_FAILED return code of 41" do
      expect(valid_rfc_exit_codes.include?(41)).to eq(true)
    end

    it "validates a CLIENT_UPGRADED return code of 213" do
      expect(valid_rfc_exit_codes.include?(213)).to eq(true)
    end
  end

  context "when Chef validates exit codes" do

    it "does write a warning on non-standard exit codes" do
      expect(Chef::Log).to receive(:warn).with(
        /^Chef attempted to exit with a non-standard exit code of 151/)
      expect(exit_codes.normalize_exit_code(151)).to eq(1)
    end

    it "returns a GENERIC_FAILURE for non-RFC exit codes" do
      expect(exit_codes.normalize_exit_code(151)).to eq(1)
    end

    it "returns GENERIC_FAILURE when no exit code is specified" do
      expect(exit_codes.normalize_exit_code()).to eq(1)
    end

    it "returns SIGINT_RECEIVED when a SIGINT is received" do
      expect(exit_codes.normalize_exit_code(Chef::Exceptions::SigInt.new("BOOM"))).to eq(2)
    end

    it "returns SIGTERM_RECEIVED when a SIGTERM is received" do
      expect(exit_codes.normalize_exit_code(Chef::Exceptions::SigTerm.new("BOOM"))).to eq(3)
    end

    it "returns GENERIC_FAILURE when an exception is specified" do
      expect(exit_codes.normalize_exit_code(Exception.new("BOOM"))).to eq(1)
    end

    it "returns AUDIT_MODE_FAILURE when there is an audit error" do
      audit_error = Chef::Exceptions::AuditError.new("BOOM")
      runtime_error = Chef::Exceptions::RunFailedWrappingError.new(audit_error)
      expect(exit_codes.normalize_exit_code(runtime_error)).to eq(42)
    end

    it "returns REBOOT_SCHEDULED when there is an reboot requested" do
      reboot_error = Chef::Exceptions::Reboot.new("BOOM")
      runtime_error = Chef::Exceptions::RunFailedWrappingError.new(reboot_error)
      expect(exit_codes.normalize_exit_code(runtime_error)).to eq(35)
    end

    it "returns REBOOT_FAILED when the reboot command fails" do
      reboot_error = Chef::Exceptions::RebootFailed.new("BOOM")
      runtime_error = Chef::Exceptions::RunFailedWrappingError.new(reboot_error)
      expect(exit_codes.normalize_exit_code(runtime_error)).to eq(41)
    end

    it "returns REBOOT_NEEDED when a reboot is pending" do
      reboot_error = Chef::Exceptions::RebootPending.new("BOOM")
      runtime_error = Chef::Exceptions::RunFailedWrappingError.new(reboot_error)
      expect(exit_codes.normalize_exit_code(runtime_error)).to eq(37)
    end

    it "returns CLIENT_UPGRADED when the client was upgraded during converge" do
      client_upgraded_error = Chef::Exceptions::ClientUpgraded.new("BOOM")
      runtime_error = Chef::Exceptions::RunFailedWrappingError.new(client_upgraded_error)
      expect(exit_codes.normalize_exit_code(runtime_error)).to eq(213)
    end

    it "returns SIGINT_RECEIVED when a SIGINT is received." do
      sigint_error = Chef::Exceptions::SigInt.new("BOOM")
      runtime_error = Chef::Exceptions::RunFailedWrappingError.new(sigint_error)
      expect(exit_codes.normalize_exit_code(runtime_error)).to eq(2)
    end

    it "returns SIGTERM_RECEIVED when a SIGTERM is received." do
      sigterm_error = Chef::Exceptions::SigTerm.new("BOOM")
      runtime_error = Chef::Exceptions::RunFailedWrappingError.new(sigterm_error)
      expect(exit_codes.normalize_exit_code(runtime_error)).to eq(3)
    end
  end

end
