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

RSpec.describe ChefUtils::DSL::DefaultPaths do
  class DefaultPathsTestClass
    include ChefUtils::DSL::DefaultPaths
  end

  before do
    allow(Gem).to receive(:bindir).and_return("/opt/ruby/bin/bundle")
    allow(RbConfig::CONFIG).to receive(:[]).with("bindir").and_return("/opt/ruby/bin")
  end

  context "on unix" do
    before do
      allow(ChefUtils).to receive(:windows?).and_return(false)
    end

    let(:test_instance) { DefaultPathsTestClass.new }

    it "works with no path" do
      env = {}
      expect(test_instance.default_paths(env)).to eql("#{Gem.bindir}:#{RbConfig::CONFIG["bindir"]}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin")
    end

    it "works with nil path" do
      env = { "PATH" => nil }
      expect(test_instance.default_paths(env)).to eql("#{Gem.bindir}:#{RbConfig::CONFIG["bindir"]}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin")
    end

    it "works with empty path" do
      env = { "PATH" => "" }
      expect(test_instance.default_paths(env)).to eql("#{Gem.bindir}:#{RbConfig::CONFIG["bindir"]}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin")
    end

    it "appends the default_paths to the end of the path, preserving any that already exist, in the same order" do
      env = { "PATH" => "/bin:/opt/app/bin:/sbin" }
      expect(test_instance.default_paths(env)).to eql("#{Gem.bindir}:#{RbConfig::CONFIG["bindir"]}:/bin:/opt/app/bin:/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin")
    end
  end

  context "on windows" do
    before do
      allow(ChefUtils).to receive(:windows?).and_return(true)
    end

    let(:test_instance) { DefaultPathsTestClass.new }

    it "works with no path" do
      env = {}
      expect(test_instance.default_paths(env)).to eql("#{Gem.bindir};#{RbConfig::CONFIG["bindir"]}")
    end

    it "works with nil path" do
      env = { "PATH" => nil }
      expect(test_instance.default_paths(env)).to eql("#{Gem.bindir};#{RbConfig::CONFIG["bindir"]}")
    end

    it "works with empty path" do
      env = { "PATH" => "" }
      expect(test_instance.default_paths(env)).to eql("#{Gem.bindir};#{RbConfig::CONFIG["bindir"]}")
    end

    it "prepends to an existing path" do
      env = { "PATH" => "%SystemRoot%\\system32;%SystemRoot%;%SystemRoot%\\System32\\Wbem;%SYSTEMROOT%\\System32\\WindowsPowerShell\\v1.0\\" }
      expect(test_instance.default_paths(env)).to eql("#{Gem.bindir};#{RbConfig::CONFIG["bindir"]};%SystemRoot%\\system32;%SystemRoot%;%SystemRoot%\\System32\\Wbem;%SYSTEMROOT%\\System32\\WindowsPowerShell\\v1.0\\")
    end
  end
end
