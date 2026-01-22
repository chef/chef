#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All rights reserved.
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

describe Chef::DelayedEvaluator do
  let(:magic) { "This is magic!" }
  let(:de) { Chef::DelayedEvaluator.new { magic } }

  describe "#inspect" do
    it "inspects the result rather than the Proc" do
      expect(de.inspect).to eq("lazy { (evaluates to) #{magic.inspect} }")
    end
  end

  describe "#call" do
    it "evaluates correctly" do
      expect(de.call).to eq(magic)
    end
  end
end
