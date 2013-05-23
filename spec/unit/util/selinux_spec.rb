#
# Author:: Serdar Sutay (<serdar@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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
    @test_instance = TestClass.new
  end

  after(:each) do
    TestClass.reset_state
  end

  describe "when selinuxenabled binary exists" do
    before do
      paths = ENV['PATH'].split(File::PATH_SEPARATOR)
      @selinux_enabled_path = File.join(paths[Random.rand(paths.length)], "selinuxenabled")
      File.stub!(:executable?) do |file_path|
        file_path == @selinux_enabled_path
      end
    end

    describe "when selinux is enabled" do
      before do
        cmd_result = mock("Cmd Result", :exitstatus => 0)
        @test_instance.should_receive(:shell_out).once.with(@selinux_enabled_path).and_return(cmd_result)
      end

      it "should report selinux is enabled" do
        @test_instance.selinux_enabled?.should be_true
        # should check the file system only once for multiple calls
        @test_instance.selinux_enabled?.should be_true
      end
    end

    describe "when selinux is disabled" do
      before do
        cmd_result = mock("Cmd Result", :exitstatus => 1)
        @test_instance.should_receive(:shell_out).once.with(@selinux_enabled_path).and_return(cmd_result)
      end

      it "should report selinux is disabled" do
        @test_instance.selinux_enabled?.should be_false
        # should check the file system only once for multiple calls
        @test_instance.selinux_enabled?.should be_false
      end
    end

    describe "when selinux gives an unexpected status" do
      before do
        cmd_result = mock("Cmd Result", :exitstatus => 101)
        @test_instance.should_receive(:shell_out).once.with(@selinux_enabled_path).and_return(cmd_result)
      end

      it "should throw an error" do
        lambda {@test_instance.selinux_enabled?}.should raise_error(RuntimeError)
      end
    end
  end

  describe "when selinuxenabled binary doesn't exist" do
    before do
      File.stub!(:executable?).and_return(false)
    end

    it "should report selinux is disabled" do
      @test_instance.selinux_enabled?.should be_false
      # should check the file system only once for multiple calls
      File.should_not_receive(:executable?)
      @test_instance.selinux_enabled?.should be_false
    end
  end

  describe "when restorecon binary exists on the system" do
    let (:path) { "/path/to/awesome" }

    before do
      paths = ENV['PATH'].split(File::PATH_SEPARATOR)
      @restorecon_enabled_path = File.join(paths[Random.rand(paths.length)], "restorecon")
      File.stub!(:executable?) do |file_path|
        file_path == @restorecon_enabled_path
      end
    end

    it "should call restorecon non-recursive by default" do
      restorecon_command = "#{@restorecon_enabled_path} -R #{path}"
      @test_instance.should_receive(:shell_out).twice.with(restorecon_command)
      @test_instance.restore_security_context(path)
      File.should_not_receive(:executable?)
      @test_instance.restore_security_context(path)
    end

    it "should call restorecon recursive when recursive is set" do
      restorecon_command = "#{@restorecon_enabled_path} -R -r #{path}"
      @test_instance.should_receive(:shell_out).twice.with(restorecon_command)
      @test_instance.restore_security_context(path, true)
      File.should_not_receive(:executable?)
      @test_instance.restore_security_context(path, true)
    end

    it "should call restorecon non-recursive when recursive is not set" do
      restorecon_command = "#{@restorecon_enabled_path} -R #{path}"
      @test_instance.should_receive(:shell_out).twice.with(restorecon_command)
      @test_instance.restore_security_context(path)
      File.should_not_receive(:executable?)
      @test_instance.restore_security_context(path)
    end

    describe "when restorecon doesn't exist on the system" do
      before do
        File.stub!(:executable?).and_return(false)
      end

      it "should log a warning message" do
        log = [ ]
        Chef::Log.stub(:warn) do |message|
          log << message
        end

        @test_instance.restore_security_context(path)
        log.should_not be_empty
        File.should_not_receive(:executable?)
        @test_instance.restore_security_context(path)
      end
    end
  end
end
