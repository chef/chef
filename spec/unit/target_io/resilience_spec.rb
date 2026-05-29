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

RSpec.describe TargetIO::Resilience do
  before do
    allow(described_class).to receive(:enabled?).and_return(true)
    allow(described_class).to receive(:max_attempts).and_return(3)
    allow(described_class).to receive(:timeout_seconds).and_return(0.1)
    allow(described_class).to receive(:retry_delay_seconds).and_return(0)
    allow(described_class).to receive(:sleep_for)
  end

  describe ".with_timeout_and_backoff" do
    it "retries timeout failures and eventually succeeds" do
      calls = 0
      result = described_class.with_timeout_and_backoff(operation: "test timeout") do
        calls += 1
        raise Timeout::Error, "timeout" if calls == 1

        :ok
      end

      expect(result).to eq(:ok)
      expect(calls).to eq(2)
      expect(described_class).to have_received(:sleep_for).with(0)
    end

    it "retries standard errors and eventually succeeds" do
      calls = 0
      result = described_class.with_timeout_and_backoff(operation: "test standard error") do
        calls += 1
        raise RuntimeError, "boom" if calls == 1

        :ok
      end

      expect(result).to eq(:ok)
      expect(calls).to eq(2)
      expect(described_class).to have_received(:sleep_for).with(0)
    end

    it "raises when max attempts are exhausted" do
      allow(described_class).to receive(:max_attempts).and_return(2)

      expect do
        described_class.with_timeout_and_backoff(operation: "always fail") do
          raise Timeout::Error, "still timing out"
        end
      end.to raise_error(Timeout::Error)
    end
  end
end
