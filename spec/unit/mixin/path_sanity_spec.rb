#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'spec_helper'

class PathSanityTestHarness
  include Chef::Mixin::PathSanity
end

describe Chef::Mixin::PathSanity do

  before do
    @sanity = PathSanityTestHarness.new
  end

  describe "when enforcing path sanity" do
    before do
      Chef::Config[:enforce_path_sanity] = true
      @ruby_bindir = '/some/ruby/bin'
      @gem_bindir = '/some/gem/bin'
      Gem.stub!(:bindir).and_return(@gem_bindir)
      RbConfig::CONFIG.stub!(:[]).with('bindir').and_return(@ruby_bindir)
      Chef::Platform.stub!(:windows?).and_return(false)
    end

    it "adds all useful PATHs that are not yet in PATH to PATH" do
      env = {"PATH" => ""}
      @sanity.enforce_path_sanity(env)
      env["PATH"].should == "#{@ruby_bindir}:#{@gem_bindir}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    end

    it "does not re-add paths that already exist in PATH" do
      env = {"PATH" => "/usr/bin:/sbin:/bin"}
      @sanity.enforce_path_sanity(env)
      env["PATH"].should == "/usr/bin:/sbin:/bin:#{@ruby_bindir}:#{@gem_bindir}:/usr/local/sbin:/usr/local/bin:/usr/sbin"
    end

    it "adds the current executing Ruby's bindir and Gem bindir to the PATH" do
      env = {"PATH" => ""}
      @sanity.enforce_path_sanity(env)
      env["PATH"].should == "#{@ruby_bindir}:#{@gem_bindir}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    end

    it "does not create entries for Ruby/Gem bindirs if they exist in SANE_PATH or PATH" do
      ruby_bindir = '/usr/bin'
      gem_bindir = '/yo/gabba/gabba'
      Gem.stub!(:bindir).and_return(gem_bindir)
      RbConfig::CONFIG.stub!(:[]).with('bindir').and_return(ruby_bindir)
      env = {"PATH" => gem_bindir}
      @sanity.enforce_path_sanity(env)
      env["PATH"].should == "/yo/gabba/gabba:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    end

    it "builds a valid windows path" do
      ruby_bindir = 'C:\ruby\bin'
      gem_bindir = 'C:\gems\bin'
      Gem.stub!(:bindir).and_return(gem_bindir)
      RbConfig::CONFIG.stub!(:[]).with('bindir').and_return(ruby_bindir)
      Chef::Platform.stub!(:windows?).and_return(true)
      env = {"PATH" => 'C:\Windows\system32;C:\mr\softie'}
      @sanity.enforce_path_sanity(env)
      env["PATH"].should == "C:\\Windows\\system32;C:\\mr\\softie;#{ruby_bindir};#{gem_bindir}"
    end
  end
end
