# frozen_string_literal: true
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

require "spec_helper"

RSpec.describe ChefUtils::DSL::Introspection do
  class IntrospectionTestClass
    include ChefUtils::DSL::Introspection
    attr_accessor :node

    def initialize(node)
      @node = node
    end
  end

  let(:node) { double("node") }

  let(:test_instance) { IntrospectionTestClass.new(node) }

  context "#effortless?" do
    # FIXME: use a real VividMash for these tests instead of stubbing
    it "is false by default" do
      expect(node).to receive(:read).with("chef_packages", "chef", "chef_effortless").and_return(nil)
      expect(ChefUtils.effortless?(node)).to be false
    end
    it "is true when ohai reports a effortless" do
      expect(node).to receive(:read).with("chef_packages", "chef", "chef_effortless").and_return(true)
      expect(ChefUtils.effortless?(node)).to be true
    end
  end

  context "#docker?" do
    # FIXME: use a real VividMash for these tests instead of stubbing
    it "is false by default" do
      expect(node).to receive(:read).with("virtualization", "systems", "docker").and_return(nil)
      expect(ChefUtils.docker?(node)).to be false
    end
    it "is true when ohai reports a docker guest" do
      expect(node).to receive(:read).with("virtualization", "systems", "docker").and_return("guest")
      expect(ChefUtils.docker?(node)).to be true
    end
    it "is false for any other value other than guest" do
      expect(node).to receive(:read).with("virtualization", "systems", "docker").and_return("some nonsense")
      expect(ChefUtils.docker?(node)).to be false
    end
  end

  context "#systemd?" do
    # FIXME: somehow test the train helpers
    it "returns false if /proc/1/comm does not exist" do
      expect(File).to receive(:exist?).with("/proc/1/comm").and_return(false)
      expect(ChefUtils.systemd?(node)).to be false
    end

    it "returns false if /proc/1/comm is not systemd" do
      expect(File).to receive(:exist?).with("/proc/1/comm").and_return(true)
      expect(File).to receive(:open).with("/proc/1/comm").and_return(StringIO.new("upstart\n"))
      expect(ChefUtils.systemd?(node)).to be false
    end

    it "returns true if /proc/1/comm is systemd" do
      expect(File).to receive(:exist?).with("/proc/1/comm").and_return(true)
      expect(File).to receive(:open).with("/proc/1/comm").and_return(StringIO.new("systemd\n"))
      expect(ChefUtils.systemd?(node)).to be true
    end
  end

  context "#kitchen?" do
    before do
      @saved = ENV["TEST_KITCHEN"]
    end
    after do
      ENV["TEST_KITCHEN"] = @saved
    end

    it "return true if ENV['TEST_KITCHEN'] is not set" do
      ENV.delete("TEST_KITCHEN")
      expect(ChefUtils.kitchen?(node)).to be false
    end

    it "return true if ENV['TEST_KITCHEN'] is nil" do
      ENV["TEST_KITCHEN"] = nil
      expect(ChefUtils.kitchen?(node)).to be false
    end

    it "return true if ENV['TEST_KITCHEN'] is set" do
      ENV["TEST_KITCHEN"] = "1"
      expect(ChefUtils.kitchen?(node)).to be true
    end
  end

  context "#ci?" do
    before do
      @saved = ENV["CI"]
    end
    after do
      ENV["CI"] = @saved
    end

    it "return true if ENV['CI'] is not set" do
      ENV.delete("CI")
      expect(ChefUtils.ci?(node)).to be false
    end

    it "return true if ENV['CI'] is nil" do
      ENV["CI"] = nil
      expect(ChefUtils.ci?(node)).to be false
    end

    it "return true if ENV['CI'] is set" do
      ENV["CI"] = "1"
      expect(ChefUtils.ci?(node)).to be true
    end
  end

  context "#has_systemd_service_unit?" do
    # FIXME: test through train helpers

    before do
      %w{ /etc /usr/lib /lib /run }.each do |base|
        allow(File).to receive(:exist?).with("#{base}/systemd/system/example.service").and_return(false)
        allow(File).to receive(:exist?).with("#{base}/systemd/system/example@.service").and_return(false)
      end
    end

    it "is false if no unit is present" do
      expect(ChefUtils.has_systemd_service_unit?("example")).to be false
    end

    it "is false if no template is present" do
      expect(ChefUtils.has_systemd_service_unit?("example@instance1")).to be false
    end

    %w{ /etc /usr/lib /lib /run }.each do |base|
      it "finds a unit in #{base}" do
        expect(File).to receive(:exist?).with("#{base}/systemd/system/example.service").and_return(true)
        expect(ChefUtils.has_systemd_service_unit?("example")).to be true
      end

      it "finds a template in #{base}" do
        expect(File).to receive(:exist?).with("#{base}/systemd/system/example@.service").and_return(true)
        expect(ChefUtils.has_systemd_service_unit?("example@instance1")).to be true
      end
    end
  end

  context "#has_systemd_unit?" do
    # FIXME: test through train helpers

    before do
      %w{ /etc /usr/lib /lib /run }.each do |base|
        allow(File).to receive(:exist?).with("#{base}/systemd/system/example.mount").and_return(false)
      end
    end

    it "is false if no unit is present" do
      expect(ChefUtils.has_systemd_unit?("example.mount")).to be false
    end

    %w{ /etc /usr/lib /lib /run }.each do |base|
      it "finds a unit in #{base}" do
        expect(File).to receive(:exist?).with("#{base}/systemd/system/example.mount").and_return(true)
        expect(ChefUtils.has_systemd_unit?("example.mount")).to be true
      end
    end
  end

  context "#include_recipe?" do
    it "is true when the recipe has been seen by the node" do
      expect(node).to receive(:recipe?).with("myrecipe").and_return(true)
      expect(ChefUtils.include_recipe?("myrecipe", node)).to be true
    end
    it "is false when the recipe has not been seen by the node" do
      expect(node).to receive(:recipe?).with("myrecipe").and_return(false)
      expect(ChefUtils.include_recipe?("myrecipe", node)).to be false
    end
    it "the alias is true when the recipe has been seen by the node" do
      expect(node).to receive(:recipe?).with("myrecipe").and_return(true)
      expect(ChefUtils.includes_recipe?("myrecipe", node)).to be true
    end
    it "the alias is false when the recipe has not been seen by the node" do
      expect(node).to receive(:recipe?).with("myrecipe").and_return(false)
      expect(ChefUtils.includes_recipe?("myrecipe", node)).to be false
    end
  end
end
