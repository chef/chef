#
# Author:: Seth Chisamore (<schisamo@chef.io>)
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

class DefaultPathsTestHarness
  include Chef::Mixin::DefaultPaths
end

describe Chef::Mixin::DefaultPaths do

  before do
    @default_paths = DefaultPathsTestHarness.new
  end

  describe "when enforcing default paths" do
    before do
      Chef::Config[:enforce_default_paths] = true
      @ruby_bindir = "/some/ruby/bin"
      @gem_bindir = "/some/gem/bin"
      allow(Gem).to receive(:bindir).and_return(@gem_bindir)
      allow(RbConfig::CONFIG).to receive(:[]).with("bindir").and_return(@ruby_bindir)
      allow(ChefUtils).to receive(:windows?).and_return(false)
    end

    it "adds all useful PATHs even if environment is an empty hash" do
      env = {}
      @default_paths.enforce_default_paths(env)
      expect(env["PATH"]).to eq("#{@gem_bindir}:#{@ruby_bindir}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin")
    end

    it "adds all useful PATHs that are not yet in PATH to PATH" do
      env = { "PATH" => "" }
      @default_paths.enforce_default_paths(env)
      expect(env["PATH"]).to eq("#{@gem_bindir}:#{@ruby_bindir}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin")
    end

    it "does not re-add paths that already exist in PATH" do
      env = { "PATH" => "/usr/bin:/sbin:/bin" }
      @default_paths.enforce_default_paths(env)
      expect(env["PATH"]).to eq("#{@gem_bindir}:#{@ruby_bindir}:/usr/bin:/sbin:/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin")
    end

    it "creates path with utf-8 encoding" do
      env = { "PATH" => "/usr/bin:/sbin:/bin:/b#{0x81.chr}t".force_encoding("ISO-8859-1") }
      @default_paths.enforce_default_paths(env)
      expect(env["PATH"].encoding.to_s).to eq("UTF-8")
    end

    it "adds the current executing Ruby's bindir and Gem bindir to the PATH" do
      env = { "PATH" => "" }
      @default_paths.enforce_default_paths(env)
      expect(env["PATH"]).to eq("#{@gem_bindir}:#{@ruby_bindir}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin")
    end

    it "does not create entries for Ruby/Gem bindirs if they exist in PATH" do
      ruby_bindir = "/usr/bin"
      gem_bindir = "/yo/gabba/gabba"
      allow(Gem).to receive(:bindir).and_return(gem_bindir)
      allow(RbConfig::CONFIG).to receive(:[]).with("bindir").and_return(ruby_bindir)
      env = { "PATH" => gem_bindir }
      @default_paths.enforce_default_paths(env)
      expect(env["PATH"]).to eq("/usr/bin:/yo/gabba/gabba:/usr/local/sbin:/usr/local/bin:/usr/sbin:/sbin:/bin")
    end

    it "builds a valid windows path" do
      ruby_bindir = 'C:\ruby\bin'
      gem_bindir = 'C:\gems\bin'
      allow(Gem).to receive(:bindir).and_return(gem_bindir)
      allow(RbConfig::CONFIG).to receive(:[]).with("bindir").and_return(ruby_bindir)
      allow(ChefUtils).to receive(:windows?).and_return(true)
      env = { "PATH" => "C:\\Windows\\system32;C:\\mr\\softie" }
      @default_paths.enforce_default_paths(env)
      expect(env["PATH"]).to eq("#{gem_bindir};#{ruby_bindir};C:\\Windows\\system32;C:\\mr\\softie")
    end
  end
end
