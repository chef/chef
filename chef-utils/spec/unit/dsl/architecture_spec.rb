# frozen_string_literal: true
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

def arch_reports_true_for(*args)
  args.each do |method|
    it "reports true for #{method}" do
      expect(described_class.send(method, node)).to be true
    end
  end
  (ARCH_HELPERS - args).each do |method|
    it "reports false for #{method}" do
      expect(described_class.send(method, node)).to be false
    end
  end
end

RSpec.describe ChefUtils::DSL::Architecture do
  let(:node) { { "kernel" => { "machine" => arch } } }

  ( HELPER_MODULES - [ described_class ] ).each do |klass|
    it "does not have methods that collide with #{klass}" do
      expect((klass.methods - Module.methods) & ARCH_HELPERS).to be_empty
    end
  end

  ARCH_HELPERS.each do |helper|
    it "has the #{helper} in the ChefUtils module" do
      expect(ChefUtils).to respond_to(helper)
    end
  end

  context "on x86_64" do
    let(:arch) { "x86_64" }

    arch_reports_true_for(:intel?, :_64_bit?)
  end

  context "on amd64" do
    let(:arch) { "amd64" }

    arch_reports_true_for(:intel?, :_64_bit?)
  end
  context "on ppc64" do
    let(:arch) { "ppc64" }

    arch_reports_true_for(:ppc64?, :_64_bit?)
  end
  context "on ppc64le" do
    let(:arch) { "ppc64le" }

    arch_reports_true_for(:ppc64le?, :_64_bit?)
  end
  context "on s390x" do
    let(:arch) { "s390x" }

    arch_reports_true_for(:s390x?, :_64_bit?)
  end
  context "on ia64" do
    let(:arch) { "ia64" }

    arch_reports_true_for(:_64_bit?)
  end
  context "on sparc64" do
    let(:arch) { "sparc64" }

    arch_reports_true_for(:_64_bit?)
  end
  context "on aarch64" do
    let(:arch) { "aarch64" }

    arch_reports_true_for(:_64_bit?, :arm?)
  end
  context "on arch64" do
    let(:arch) { "arch64" }

    arch_reports_true_for(:_64_bit?, :arm?)
  end
  context "on arm64" do
    let(:arch) { "arm64" }

    arch_reports_true_for(:_64_bit?, :arm?)
  end
  context "on sun4v" do
    let(:arch) { "sun4v" }

    arch_reports_true_for(:sparc?, :_64_bit?)
  end
  context "on sun4u" do
    let(:arch) { "sun4u" }

    arch_reports_true_for(:sparc?, :_64_bit?)
  end
  context "on i86pc" do
    let(:arch) { "i86pc" }

    arch_reports_true_for(:i386?, :intel?, :_32_bit?)
  end
  context "on i386" do
    let(:arch) { "i386" }

    arch_reports_true_for(:i386?, :intel?, :_32_bit?)
  end
  context "on i686" do
    let(:arch) { "i686" }

    arch_reports_true_for(:i386?, :intel?, :_32_bit?)
  end
  context "on powerpc" do
    let(:arch) { "powerpc" }

    arch_reports_true_for(:powerpc?, :_32_bit?)
  end
  context "on armhf" do
    let(:arch) { "armhf" }

    arch_reports_true_for(:armhf?, :_32_bit?, :arm?)
  end
  context "on armv6l" do
    let(:arch) { "armv6l" }

    arch_reports_true_for(:armhf?, :_32_bit?, :arm?)
  end
  context "on armv7l" do
    let(:arch) { "armv7l" }

    arch_reports_true_for(:armhf?, :_32_bit?, :arm?)
  end

  context "on s390" do
    let(:arch) { "s390" }

    arch_reports_true_for(:s390?, :_32_bit?)
  end
end
