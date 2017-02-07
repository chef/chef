#
# Author:: Serdar Sutay (<serdar@chef.io>)
# Copyright:: Copyright 2013-2017, Chef Software Inc.
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

describe Chef::Util::Selinux do
  class TestClass
    include Chef::Util::Selinux

    def self.reset_state
      @@selinux_enabled = nil
      @@restorecon_path = nil
      @@selinuxenabled_path = nil
    end
  end

  before do
    TestClass.reset_state
    @test_instance = TestClass.new
  end

  after(:each) do
    TestClass.reset_state
  end

  it "each part of ENV['PATH'] should be checked" do
    expected_paths = ENV["PATH"].split(File::PATH_SEPARATOR) + [ "/bin", "/usr/bin", "/sbin", "/usr/sbin" ]

    expected_paths.each do |bin_path|
      selinux_path = File.join(bin_path, "selinuxenabled")
      expect(File).to receive(:executable?).with(selinux_path).and_return(false)
    end

    expect(@test_instance.selinux_enabled?).to be_falsey
  end

  describe "when selinuxenabled binary exists" do
    before do
      @selinux_enabled_path = File.join("/sbin", "selinuxenabled")
      allow(File).to receive(:executable?) do |file_path|
        expect(file_path.end_with?("selinuxenabled")).to be_truthy
        file_path == @selinux_enabled_path
      end
    end

    describe "when selinux is enabled" do
      before do
        cmd_result = double("Cmd Result", :exitstatus => 0)
        expect(@test_instance).to receive(:shell_out!).once.with(@selinux_enabled_path, { :returns => [0, 1] }).and_return(cmd_result)
      end

      it "should report selinux is enabled" do
        expect(@test_instance.selinux_enabled?).to be_truthy
        # should check the file system only once for multiple calls
        expect(@test_instance.selinux_enabled?).to be_truthy
      end
    end

    describe "when selinux is disabled" do
      before do
        cmd_result = double("Cmd Result", :exitstatus => 1)
        expect(@test_instance).to receive(:shell_out!).once.with(@selinux_enabled_path, { :returns => [0, 1] }).and_return(cmd_result)
      end

      it "should report selinux is disabled" do
        expect(@test_instance.selinux_enabled?).to be_falsey
        # should check the file system only once for multiple calls
        expect(@test_instance.selinux_enabled?).to be_falsey
      end
    end

    describe "when selinux gives an unexpected status" do
      before do
        cmd_result = double("Cmd Result", :exitstatus => 101)
        expect(@test_instance).to receive(:shell_out!).once.with(@selinux_enabled_path, { :returns => [0, 1] }).and_return(cmd_result)
      end

      it "should throw an error" do
        expect { @test_instance.selinux_enabled? }.to raise_error(RuntimeError)
      end
    end
  end

  describe "when selinuxenabled binary doesn't exist" do
    before do
      allow(File).to receive(:executable?) do |file_path|
        expect(file_path.end_with?("selinuxenabled")).to be_truthy
        false
      end
    end

    it "should report selinux is disabled" do
      expect(@test_instance.selinux_enabled?).to be_falsey
      # should check the file system only once for multiple calls
      expect(File).not_to receive(:executable?)
      expect(@test_instance.selinux_enabled?).to be_falsey
    end
  end

  describe "when restorecon binary exists on the system" do
    let (:path) { "/path/to/awesome directory" }

    before do
      @restorecon_enabled_path = File.join("/sbin", "restorecon")
      allow(File).to receive(:executable?) do |file_path|
        expect(file_path.end_with?("restorecon")).to be_truthy
        file_path == @restorecon_enabled_path
      end
    end

    it "should call restorecon non-recursive by default" do
      restorecon_command = "#{@restorecon_enabled_path} -R \"#{path}\""
      expect(@test_instance).to receive(:shell_out!).twice.with(restorecon_command)
      @test_instance.restore_security_context(path)
      expect(File).not_to receive(:executable?)
      @test_instance.restore_security_context(path)
    end

    it "should call restorecon recursive when recursive is set" do
      restorecon_command = "#{@restorecon_enabled_path} -R -r \"#{path}\""
      expect(@test_instance).to receive(:shell_out!).twice.with(restorecon_command)
      @test_instance.restore_security_context(path, true)
      expect(File).not_to receive(:executable?)
      @test_instance.restore_security_context(path, true)
    end

    it "should call restorecon non-recursive when recursive is not set" do
      restorecon_command = "#{@restorecon_enabled_path} -R \"#{path}\""
      expect(@test_instance).to receive(:shell_out!).twice.with(restorecon_command)
      @test_instance.restore_security_context(path)
      expect(File).not_to receive(:executable?)
      @test_instance.restore_security_context(path)
    end

    describe "when restorecon doesn't exist on the system" do
      it "should log a warning message" do
        allow(File).to receive(:executable?).with(/restorecon$/).and_return(false)
        expect(Chef::Log).to receive(:warn).with(/Can not find 'restorecon' on the system. Skipping selinux security context restore./).at_least(:once)
        @test_instance.restore_security_context(path)
        expect(File).not_to receive(:executable?)
        @test_instance.restore_security_context(path)
      end
    end
  end
end
