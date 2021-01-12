#
# Author:: Kaustubh Deorukhkar (<kaustubh@clogeny.com>)
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
require "chef/mixin/shell_out"
require "fileutils"

describe Chef::Resource::Service, :requires_root, :aix_only do

  include Chef::Mixin::ShellOut

  # Platform specific validation routines.
  def service_should_be_started(file_name)
    # The existence of this file indicates that the service was started.
    expect(File.exist?("#{Dir.tmpdir}/#{file_name}")).to be_truthy
  end

  def service_should_be_stopped(file_name)
    expect(File.exist?("#{Dir.tmpdir}/#{file_name}")).to be_falsey
  end

  def valid_symlinks(expected_output, run_level = nil, status = nil, priority = nil)
    directory = []
    if priority.is_a? Hash
      priority.each do |level, o|
        directory << "/etc/rc.d/rc#{level}.d/#{(o[0] == :start ? "S" : "K")}#{o[1]}#{new_resource.service_name}"
      end
      directory
    else
      directory << "/etc/rc.d/rc#{run_level}.d/#{status}#{priority}#{new_resource.service_name}"
    end
    expect(Dir.glob(directory)).to eq(expected_output)
    File.delete(*directory)
  end

  def delete_test_files
    files = Dir.glob("#{Dir.tmpdir}/chefinit[a-z_]*.txt")
    File.delete(*files)
  end

  # Actual tests
  let(:new_resource) do
    run_context = Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
    new_resource = Chef::Resource::Service.new("chefinittest", run_context)
    new_resource.provider Chef::Provider::Service::AixInit
    new_resource.supports({ status: true, restart: true, reload: true })
    new_resource
  end

  let(:provider) do
    provider = new_resource.provider_for_action(new_resource.action)
    provider
  end

  before(:all) do
    File.delete("/etc/rc.d/init.d/chefinittest") if File.exist?("/etc/rc.d/init.d/chefinittest")
    FileUtils.cp((File.join(__dir__, "/../assets/chefinittest")).to_s, "/etc/rc.d/init.d/chefinittest")
  end

  after(:all) do
    File.delete("/etc/rc.d/init.d/chefinittest") if File.exist?("/etc/rc.d/init.d/chefinittest")
  end

  before(:each) do
    delete_test_files
  end

  after(:each) do
    delete_test_files
  end

  describe "start service" do
    it "should start the service" do
      new_resource.run_action(:start)
      service_should_be_started("chefinittest.txt")
    end
  end

  describe "stop service" do
    before do
      new_resource.run_action(:start)
    end

    it "should stop the service" do
      new_resource.run_action(:stop)
      service_should_be_stopped("chefinittest.txt")
    end
  end

  describe "restart service" do
    before do
      new_resource.run_action(:start)
    end

    it "should restart the service" do
      new_resource.run_action(:restart)
      service_should_be_started("chefinittest_restart.txt")
    end
  end

  describe "reload service" do
    before do
      new_resource.run_action(:start)
    end

    it "should reload the service" do
      new_resource.run_action(:reload)
      service_should_be_started("chefinittest_reload.txt")
    end
  end

  describe "enable service" do

    context "when the service doesn't set a priority" do
      it "creates symlink with status S" do
        new_resource.run_action(:enable)
        valid_symlinks(["/etc/rc.d/rc2.d/Schefinittest"], 2, "S")
      end
    end

    context "when the service sets a simple priority (integer)" do
      before do
        new_resource.priority(75)
      end

      it "creates a symlink with status S and a priority" do
        new_resource.run_action(:enable)
        valid_symlinks(["/etc/rc.d/rc2.d/S75chefinittest"], 2, "S", 75)
      end
    end

    context "when the service sets complex priorities (hash)" do
      before do
        priority = { 2 => [:start, 20], 3 => [:stop, 10] }
        new_resource.priority(priority)
      end

      it "create symlink with status start (S) or stop (K) and a priority " do
        new_resource.run_action(:enable)
        valid_symlinks(["/etc/rc.d/rc2.d/S20chefinittest", "/etc/rc.d/rc3.d/K10chefinittest"], 2, "S", new_resource.priority)
      end
    end
  end

  describe "disable_service" do

    context "when the service doesn't set a priority" do
      before do
        File.symlink("/etc/rc.d/init.d/chefinittest", "/etc/rc.d/rc2.d/Schefinittest")
      end

      after do
        File.delete("/etc/rc.d/rc2.d/Schefinittest") if File.exist?("/etc/rc.d/rc2.d/chefinittest")
      end

      it "creates symlink with status K" do
        new_resource.run_action(:disable)
        valid_symlinks(["/etc/rc.d/rc2.d/Kchefinittest"], 2, "K")
      end
    end

    context "when the service sets a simple priority (integer)" do
      before do
        new_resource.priority(75)
        File.symlink("/etc/rc.d/init.d/chefinittest", "/etc/rc.d/rc2.d/Schefinittest")
      end

      after do
        File.delete("/etc/rc.d/rc2.d/Schefinittest") if File.exist?("/etc/rc.d/rc2.d/chefinittest")
      end

      it "creates a symlink with status K and a priority" do
        new_resource.run_action(:disable)
        valid_symlinks(["/etc/rc.d/rc2.d/K25chefinittest"], 2, "K", 25)
      end
    end

    context "when the service sets complex priorities (hash)" do
      before do
        @priority = { 2 => [:stop, 20], 3 => [:start, 10] }
        new_resource.priority(@priority)
        File.symlink("/etc/rc.d/init.d/chefinittest", "/etc/rc.d/rc2.d/Schefinittest")
      end

      after do
        File.delete("/etc/rc.d/rc2.d/Schefinittest") if File.exist?("/etc/rc.d/rc2.d/chefinittest")
      end

      it "create symlink with status stop (K) and a priority " do
        new_resource.run_action(:disable)
        valid_symlinks(["/etc/rc.d/rc2.d/K80chefinittest"], 2, "K", 80)
      end
    end
  end
end
