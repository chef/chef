# Copyright:: Copyright 2017, Noah Kantrowitz
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
require "chef/version_string"

describe Chef::VersionString do
  let(:input) { "1.2.3" }
  subject(:described_object) { described_class.new(input) }

  it { is_expected.to eq "1.2.3" }
  it { is_expected.to eql "1.2.3" }
  it { is_expected.to be == "1.2.3" }
  it { is_expected.to be < "abc" }
  it { is_expected.to be > "0" }
  it { is_expected.to eq described_class.new("1.2.3") }
  it { is_expected.to be == described_class.new("1.2.3") }

  context "with !=" do
    subject { described_object != "1.2.4" }
    it { is_expected.to be true }
  end

  context "with +" do
    subject { described_object + "asdf" }
    it { is_expected.to eq "1.2.3asdf" }
  end

  context "with *" do
    subject { described_object * 3 }
    it { is_expected.to eq "1.2.31.2.31.2.3" }
  end

  context "with version-like comparisons" do
    subject { described_class.new("1.02.3") }

    it { is_expected.to eq "1.2.3" }
    it { is_expected.to be > "1.2.2" }
    it { is_expected.to be > "1.2.3a" }
    it { is_expected.to be < "1.2.4" }
  end

  context "with =~ Regexp" do
    subject { described_object =~ /^1/ }
    it { is_expected.to eq 0 }
  end

  context "with =~ Requirement" do
    subject { described_object =~ Gem::Requirement.create("~> 1.0") }
    it { is_expected.to be true }
  end

  context "with =~ String" do
    subject { described_object =~ "~> 1.0" }
    it { is_expected.to be true }
  end

  context "with Regexp =~" do
    subject { /^2/ =~ described_object }
    it { is_expected.to be nil }
  end

  context "with String =~" do
    subject { "~> 1.0" =~ described_object }
    it { expect { subject }.to raise_error TypeError }
  end
end
